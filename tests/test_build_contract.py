import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class ApacheWindowsBuildContractTests(unittest.TestCase):
    def test_apr_util_links_the_bundled_expat_import_library(self):
        script = (ROOT / "build_all.bat").read_text(encoding="utf-8")
        options = self._find_assignment(script, "APR-UTIL_CMAKE_OPTS")

        self.assertIn("-DEXPAT_INCLUDE_DIR=%PREFIX%/include", options)
        self.assertIn("-DEXPAT_LIBRARY=%PREFIX%/lib/libexpat.lib", options)

    def test_build_rejects_strawberry_perl_expat_dependency(self):
        script = (ROOT / "build_all.bat").read_text(encoding="utf-8")

        self.assertIn("dumpbin /dependents", script.lower())
        self.assertIn("libexpat.dll", script.lower())
        self.assertIn("libexpat-1__.dll", script.lower())
        self.assertRegex(
            script.lower(),
            r"findstr[^\r\n]+libexpat-1__\.dll[\s\S]+exit /b 1",
        )

    def test_build_smoke_tests_httpd_with_an_isolated_path(self):
        script = (ROOT / "build_all.bat").read_text(encoding="utf-8")

        self.assertIn('set "PATH=%PREFIX%\\bin;%SystemRoot%\\System32;%SystemRoot%"', script)
        self.assertIn('"%PREFIX%\\bin\\httpd.exe" -v', script)

    @staticmethod
    def _find_assignment(script, variable):
        match = re.search(
            rf"^\s*set\s+{re.escape(variable)}=(?P<value>.+)$",
            script,
            re.MULTILINE | re.IGNORECASE,
        )
        if not match:
            raise AssertionError(f"Assignment not found: {variable}")
        return match.group("value")


if __name__ == "__main__":
    unittest.main()
