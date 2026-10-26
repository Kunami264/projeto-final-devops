"""Testes de vulnerabilidades (M8).

Analisam o código, os ficheiros de dependências e as imagens já construídas — não
precisam do ambiente a correr. Cada teste grava o resultado em tests/security/reports/.

- pip-audit: dependências Python de cada serviço (requirements-prd.txt e requirements-tracing.txt)
- Trivy (fs): os mesmos ficheiros de dependências, com a base de dados do Trivy
- Trivy (imagem): as imagens indicadas em TRIVY_IMAGES (em STG, as imagens que seguem para PRD)

A política é não ignorar vulnerabilidades: qualquer HIGH ou CRITICAL faz falhar o teste.
"""
import json
import os
import shutil
import subprocess
import sys
from collections import Counter
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
REPORTS = ROOT / "tests" / "security" / "reports"
TRIVY_IMAGE = os.getenv("TRIVY_IMAGE", "aquasec/trivy:0.76.1")
BLOCKING = {"HIGH", "CRITICAL"}

REQUIREMENTS = sorted(
    str(p.relative_to(ROOT))
    for p in ROOT.glob("service-*/requirements-*.txt")
    if p.name != "requirements-dev.txt"
)
IMAGES = os.getenv("TRIVY_IMAGES", "").split()


def _report_name(prefix: str, target: str) -> str:
    target = target.removesuffix(".txt").replace("/", "_").replace(":", "_")
    return f"{prefix}_{target}.txt"


def _write_report(name: str, text: str) -> None:
    REPORTS.mkdir(parents=True, exist_ok=True)
    (REPORTS / name).write_text(text, encoding="utf-8")


def _trivy(*args: str) -> dict:
    if shutil.which("docker") is None:
        pytest.skip("Docker não disponível: o Trivy corre num contentor")
    cmd = [
        "docker", "run", "--rm",
        "-v", "trivy-cache:/root/.cache",
        "-v", f"{ROOT}:/src:ro",
        "-v", "/var/run/docker.sock:/var/run/docker.sock",
        "-e", r"TRIVY_FILE_PATTERNS=pip:requirements-.*\.txt",
        TRIVY_IMAGE, *args, "--scanners", "vuln", "--format", "json", "--quiet",
    ]
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=900)
    assert result.returncode == 0, f"O Trivy não correu:\n{result.stderr}"
    return json.loads(result.stdout)


def _summarise(report: dict, title: str) -> tuple[str, list[str]]:
    counts: Counter = Counter()
    lines = [f"# {title}", ""]
    blocking = []
    for res in report.get("Results", []):
        for vuln in res.get("Vulnerabilities") or []:
            counts[vuln["Severity"]] += 1
            line = (
                f"{vuln['Severity']:<8} {vuln['VulnerabilityID']:<22} {vuln['PkgName']} "
                f"{vuln['InstalledVersion']} -> {vuln.get('FixedVersion') or 'sem correção'} ({res['Target']})"
            )
            lines.append(line)
            if vuln["Severity"] in BLOCKING:
                blocking.append(line)
    lines.insert(2, "Total por severidade: " + (", ".join(f"{k}={v}" for k, v in sorted(counts.items())) or "0 vulnerabilidades"))
    return "\n".join(lines) + "\n", blocking


@pytest.mark.parametrize("requirements", REQUIREMENTS)
def test_pip_audit_dependencias(requirements):
    result = subprocess.run(
        [sys.executable, "-m", "pip_audit", "-r", str(ROOT / requirements),
         "--progress-spinner", "off", "--desc", "on"],
        capture_output=True, text=True, timeout=900,
    )
    _write_report(_report_name("pip-audit", requirements), result.stdout + result.stderr)
    assert result.returncode == 0, f"pip-audit encontrou vulnerabilidades em {requirements}:\n{result.stdout}{result.stderr}"


def test_trivy_dependencias():
    report = _trivy("fs", "/src")
    text, blocking = _summarise(report, "Trivy — dependências Python (requirements-*.txt)")
    _write_report("trivy_dependencias.txt", text)
    assert not blocking, "Vulnerabilidades HIGH/CRITICAL nas dependências:\n" + "\n".join(blocking)


@pytest.mark.skipif(not IMAGES, reason="TRIVY_IMAGES não definido (análise de imagens só em STG)")
@pytest.mark.parametrize("image", IMAGES)
def test_trivy_imagem(image):
    report = _trivy("image", image)
    text, blocking = _summarise(report, f"Trivy — imagem {image}")
    _write_report(_report_name("trivy_imagem", image), text)
    assert not blocking, f"Vulnerabilidades HIGH/CRITICAL na imagem {image}:\n" + "\n".join(blocking)
