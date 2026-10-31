import os
from pathlib import Path
import subprocess
import tempfile
import textwrap
import unittest

import yaml


CHART = Path(__file__).resolve().parents[1] / "secure-enclave"
RESOLVER = "Server:\t10.96.0.10\nAddress:\t10.96.0.10:53\n\n"


def render_dns_container(endpoint="https://management.example.test"):
    rendered = subprocess.run(
        [
            "helm", "template", "dns-test", str(CHART),
            "--show-only", "templates/pre-install-hook.yaml",
            "--set", "managementApp.memberId=test-member",
            "--set-string", f"managementApp.endpoint={endpoint}",
            "--set", "setupApp.enabled=false",
            "--set", "trustedOutputApp.enabled=false",
        ],
        check=True,
        text=True,
        capture_output=True,
    )
    job = next(
        document for document in yaml.safe_load_all(rendered.stdout)
        if document and document["kind"] == "Job"
    )
    return next(
        container for container in job["spec"]["template"]["spec"]["initContainers"]
        if container["name"] == "dnsutils"
    )


class BootstrapDnsTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.container = render_dns_container()

    def run_discovery(self, output, status=0, previous="", container=None):
        container = container or self.container
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "bin").mkdir()
            fixture = root / "lookup-output"
            fixture.write_text(output)
            arguments = root / "lookup-arguments"
            stub = root / "bin" / "nslookup"
            stub.write_text(textwrap.dedent("""\
                #!/bin/sh
                printf '%s\\n' "$@" > "$DNS_ARGUMENTS"
                cat "$DNS_OUTPUT"
                exit "$DNS_STATUS"
                """))
            stub.chmod(0o755)
            addresses = root / "ip_addresses"
            addresses.write_text(previous)
            environment = dict(
                os.environ,
                PATH=f"{root / 'bin'}:{os.environ['PATH']}",
                DNS_OUTPUT=str(fixture),
                DNS_ARGUMENTS=str(arguments),
                DNS_STATUS=str(status),
            )
            result = subprocess.run(
                [*container["command"], *container["args"]],
                cwd=root,
                env=environment,
                text=True,
                capture_output=True,
            )
            return result, addresses.read_text(), arguments.read_text()

    def test_output_is_in_the_shared_volume(self):
        self.assertEqual(self.container["workingDir"], "/tmp")
        self.assertTrue(any(
            mount["name"] == "temp-volume" and mount["mountPath"].rstrip("/") == "/tmp"
            for mount in self.container["volumeMounts"]
        ))

    def test_resolver_header_is_not_an_answer(self):
        result, addresses, arguments = self.run_discovery(
            RESOLVER + "Non-authoritative answer:\n"
            "Name:\tmanagement.example.test\nAddress:\t203.0.113.8\n"
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(addresses, "203.0.113.8\n")
        self.assertEqual(arguments, "management.example.test\n")

    def test_multiple_answers_cname_ipv6_and_duplicates(self):
        result, addresses, _ = self.run_discovery(
            RESOLVER + "Non-authoritative answer:\n"
            "management.example.test canonical name = target.example.test\n"
            "Name: target.example.test\nAddress 1: 203.0.113.8 target.example.test\n"
            "Name: target.example.test\nAddress 2: 203.0.113.9 target.example.test\n"
            "Name: target.example.test\nAddress 3: 2001:db8::8 target.example.test\n"
            "Name: target.example.test\nAddress 4: ::ffff:203.0.113.8 target.example.test\n"
            "Name: target.example.test\nAddress 5: 203.0.113.8 target.example.test\n"
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(addresses, "203.0.113.8\n203.0.113.9\n")

    def test_nxdomain_does_not_publish_the_resolver(self):
        result, addresses, _ = self.run_discovery(
            RESOLVER + "** server can't find management.example.test: NXDOMAIN\n",
            status=1,
            previous="203.0.113.7\n",
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("DNS lookup failed", result.stderr)
        self.assertEqual(addresses, "")

    def test_failed_lookup_rejects_even_an_address_in_its_output(self):
        result, addresses, _ = self.run_discovery(
            RESOLVER + "Name: management.example.test\nAddress: 203.0.113.8\n",
            status=1,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(addresses, "")

    def test_resolver_only_and_empty_responses_fail(self):
        for output in (RESOLVER, ""):
            with self.subTest(output=output):
                result, addresses, _ = self.run_discovery(output)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(addresses, "")

    def test_ipv6_only_response_fails(self):
        result, addresses, _ = self.run_discovery(
            RESOLVER + "Name: management.example.test\nAddress: 2001:db8::8\n"
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(addresses, "")

    def test_malformed_answer_invalidates_the_entire_set(self):
        for invalid in (
            "256.0.0.1", "203.0.113", "203.0.113.8junk",
            "203.0.113.008", "203.0.113.8:53", "",
        ):
            with self.subTest(address=invalid):
                result, addresses, _ = self.run_discovery(
                    RESOLVER + "Name: management.example.test\nAddress: 203.0.113.8\n"
                    f"Address: {invalid}\n",
                    previous="203.0.113.7\n",
                )
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(addresses, "")

    def test_success_replaces_previous_output(self):
        result, addresses, _ = self.run_discovery(
            RESOLVER + "Name: management.example.test\nAddress: 203.0.113.8\n",
            previous="203.0.113.7\n203.0.113.7\n",
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(addresses, "203.0.113.8\n")

    def test_hostname_is_passed_as_one_literal_argument(self):
        host = "management.example.test'$(printf unsafe)"
        container = render_dns_container(f"https://{host}")
        result, addresses, arguments = self.run_discovery(
            RESOLVER + "Name: management.example.test\nAddress: 203.0.113.8\n",
            container=container,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(addresses, "203.0.113.8\n")
        self.assertEqual(arguments, host + "\n")


if __name__ == "__main__":
    unittest.main()
