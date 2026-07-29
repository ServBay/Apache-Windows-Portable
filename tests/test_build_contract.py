import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class ApacheWindowsBuildContractTests(unittest.TestCase):
    def test_workflow_exposes_only_strawberry_perl_not_its_c_toolchain(self):
        workflow = (
            ROOT / ".github" / "workflows" / "build-apache-windows.yml"
        ).read_text(encoding="utf-8")

        self.assertNotIn('"C:\\Strawberry\\c\\bin"', workflow)
        self.assertIn('"C:\\Strawberry\\perl\\bin"', workflow)
        self.assertIn("notmatch '^C:\\\\Strawberry\\\\c", workflow)

    def test_cmake_ignores_strawberry_and_prefers_the_packaged_prefix(self):
        script = (ROOT / "build_all.bat").read_text(encoding="utf-8")
        options = self._find_assignment(script, "SERVBAY_CMAKE_FIND_OPTS")

        self.assertIn("-DCMAKE_PREFIX_PATH=%PREFIX%", options)
        self.assertIn("-DCMAKE_IGNORE_PREFIX_PATH=C:/Strawberry/c", options)
        self.assertIn("-DCMAKE_FIND_USE_PACKAGE_REGISTRY=OFF", options)
        self.assertIn("-DCMAKE_FIND_USE_SYSTEM_PACKAGE_REGISTRY=OFF", options)
        self.assertIn("-DCMAKE_POLICY_VERSION_MINIMUM=3.5", options)
        self.assertIn("call :reject_strawberry_cmake_cache", script)

    def test_zlib_and_libxml2_consumers_link_the_bundled_import_libraries(self):
        script = (ROOT / "build_all.bat").read_text(encoding="utf-8")

        for variable in (
            "LIBXML2_CMAKE_OPTS",
            "CURL_CMAKE_OPTS",
            "HTTPD_CMAKE_OPTS",
        ):
            with self.subTest(variable=variable):
                options = self._find_assignment(script, variable)
                self.assertIn("-DZLIB_INCLUDE_DIR=%PREFIX%/include", options)
                self.assertIn("-DZLIB_LIBRARY=%PREFIX%/lib/zlib.lib", options)

        httpd_options = self._find_assignment(script, "HTTPD_CMAKE_OPTS")
        self.assertIn(
            "-DLIBXML2_INCLUDE_DIR=%PREFIX%/include/libxml2", httpd_options
        )
        self.assertIn(
            "-DLIBXML2_LIBRARY=%PREFIX%/lib/libxml2.lib", httpd_options
        )

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

    def test_build_scans_every_packaged_pe_dependency(self):
        script = (ROOT / "build_all.bat").read_text(encoding="utf-8")
        verifier = (
            ROOT / "tools" / "verify_portable_dependencies.ps1"
        ).read_text(encoding="utf-8")

        self.assertIn("verify_portable_dependencies.ps1", script)
        self.assertIn("Get-ChildItem", verifier)
        self.assertIn("-Recurse", verifier)
        self.assertIn('".exe"', verifier)
        self.assertIn('".dll"', verifier)
        self.assertIn('".so"', verifier)
        self.assertIn("/dependents", verifier)
        self.assertIn("Missing packaged runtime dependencies", verifier)

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
