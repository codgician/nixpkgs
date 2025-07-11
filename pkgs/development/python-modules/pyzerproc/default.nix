{
  lib,
  bleak,
  click,
  buildPythonPackage,
  fetchFromGitHub,
  pytest-asyncio,
  pytest-mock,
  pythonAtLeast,
  pytest-cov-stub,
  pytestCheckHook,
  pythonOlder,
}:

buildPythonPackage rec {
  pname = "pyzerproc";
  version = "0.4.12";
  format = "setuptools";

  disabled = pythonOlder "3.9";

  src = fetchFromGitHub {
    owner = "emlove";
    repo = "pyzerproc";
    tag = version;
    hash = "sha256-vS0sk/KjDhWispZvCuGlmVLLfeFymHqxwNzNqNRhg6k=";
  };

  propagatedBuildInputs = [
    bleak
    click
  ];

  nativeCheckInputs = [
    pytest-asyncio
    pytest-mock
    pytest-cov-stub
    pytestCheckHook
  ];

  disabledTestPaths = lib.optionals (pythonAtLeast "3.11") [
    # unittest.mock.InvalidSpecError: Cannot spec a Mock object.
    "tests/test_light.py"
  ];

  pythonImportsCheck = [ "pyzerproc" ];

  meta = with lib; {
    description = "Python library to control Zerproc Bluetooth LED smart string lights";
    mainProgram = "pyzerproc";
    homepage = "https://github.com/emlove/pyzerproc";
    license = with licenses; [ asl20 ];
    maintainers = with maintainers; [ fab ];
    platforms = platforms.linux;
  };
}
