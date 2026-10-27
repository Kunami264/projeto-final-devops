daniel-almeida@daniel-ubuntu:~/Transferências/ProjetoFinal$ make test-stg
===== [STG] A abrir port-forwards e a executar os testes =====
============================= test session starts ==============================
platform linux -- Python 3.12.13, pytest-9.1.1, pluggy-1.7.0 -- /home/daniel-almeida/Transferências/ProjetoFinal/.venv/bin/python
cachedir: .pytest_cache
rootdir: /home/daniel-almeida/Transferências/ProjetoFinal
configfile: pytest.ini
plugins: anyio-4.15.1, platformdirs-4.13.5
collected 15 items

tests/integration/test_integration.py::test_keycloak_is_healthy PASSED                                   [  6%]
tests/integration/test_integration.py::test_users_service_is_healthy PASSED                              [ 13%]
tests/integration/test_integration.py::test_orders_service_is_healthy PASSED                             [ 20%]
tests/integration/test_integration.py::test_users_metrics_endpoint_is_exposed PASSED                     [ 26%]
tests/integration/test_integration.py::test_orders_endpoint_requires_authentication PASSED               [ 33%]
tests/integration/test_integration.py::test_order_creation_calls_users_service_end_to_end PASSED         [ 40%]
tests/integration/test_integration.py::test_order_creation_with_invalid_user_returns_404 PASSED          [ 46%]
tests/integration/test_integration.py::test_create_edit_and_delete_user_and_order_end_to_end PASSED      [ 53%]
tests/integration/test_integration.py::test_create_user_requires_authentication PASSED                   [ 60%]
tests/integration/test_integration.py::test_backoffice_serves_the_application PASSED                     [ 66%]
tests/integration/test_integration.py::test_backoffice_login_and_crud_through_its_own_address PASSED     [ 73%]
tests/integration/test_integration.py::test_backoffice_does_not_expose_keycloak_admin PASSED             [ 80%]
tests/smoke/test_smoke.py::test_users_service_responds PASSED                                            [ 86%]
tests/smoke/test_smoke.py::test_orders_service_responds PASSED                                           [ 93%]
tests/smoke/test_smoke.py::test_backoffice_responds PASSED                                               [100%]

============================== 15 passed in 0.90s ==============================

===== [SEGURANÇA] pip-audit e Trivy — dependências (relatórios em tests/security/reports) =====
TRIVY_IMAGE=aquasec/trivy:0.76.1 TRIVY_IMAGES= .venv/bin/python -m pytest tests/security -v
============================= test session starts ==============================
platform linux -- Python 3.12.13, pytest-9.1.1, pluggy-1.7.0 -- /home/daniel-almeida/Transferências/ProjetoFinal/.venv/bin/python
cachedir: .pytest_cache
rootdir: /home/daniel-almeida/Transferências/ProjetoFinal
configfile: pytest.ini
plugins: anyio-4.15.1, platformdirs-4.13.5
collected 6 items

tests/security/test_vulnerabilidades.py::test_pip_audit_dependencias[service-orders/requirements-prd.txt] PASSED      [ 16%]
tests/security/test_vulnerabilidades.py::test_pip_audit_dependencias[service-orders/requirements-tracing.txt] PASSED  [ 33%]
tests/security/test_vulnerabilidades.py::test_pip_audit_dependencias[service-users/requirements-prd.txt] PASSED       [ 50%]
tests/security/test_vulnerabilidades.py::test_pip_audit_dependencias[service-users/requirements-tracing.txt] PASSED   [ 66%]
tests/security/test_vulnerabilidades.py::test_trivy_dependencias PASSED                                               [ 83%]
tests/security/test_vulnerabilidades.py::test_trivy_imagem[NOTSET] SKIPPED (TRIVY_IMAGES não definido (análise de imagens só em STG))  [100%]

========================= 5 passed, 1 skipped in 25.76s =========================

===== [SEGURANÇA] Trivy — imagens stg (relatórios em tests/security/reports) =====
TRIVY_IMAGE=aquasec/trivy:0.76.1 TRIVY_IMAGES="ghcr.io/kunami264/projeto-final-devops/service-users:stg ghcr.io/kunami264/projeto-final-devops/service-orders:stg ghcr.io/kunami264/projeto-final-devops/web:stg" \
        .venv/bin/python -m pytest tests/security -v -k trivy_imagem
============================= test session starts ==============================
platform linux -- Python 3.12.13, pytest-9.1.1, pluggy-1.7.0 -- /home/daniel-almeida/Transferências/ProjetoFinal/.venv/bin/python
cachedir: .pytest_cache
rootdir: /home/daniel-almeida/Transferências/ProjetoFinal
configfile: pytest.ini
plugins: anyio-4.15.1, platformdirs-4.13.5
collected 8 items / 5 deselected / 3 selected

tests/security/test_vulnerabilidades.py::test_trivy_imagem[ghcr.io/kunami264/projeto-final-devops/service-users:stg] PASSED   [ 33%]
tests/security/test_vulnerabilidades.py::test_trivy_imagem[ghcr.io/kunami264/projeto-final-devops/service-orders:stg] PASSED  [ 66%]
tests/security/test_vulnerabilidades.py::test_trivy_imagem[ghcr.io/kunami264/projeto-final-devops/web:stg] PASSED             [100%]

======================= 3 passed, 5 deselected in 2.56s ========================

===== [STG] ✅ Staging validado — a preparar PRD =====
===== [STG→PRD] Promoção das imagens validadas (stg → main, sem novo build) =====
sudo: preserving the entire environment is not supported, '-E' is ignored
unpacking ghcr.io/kunami264/projeto-final-devops/service-users:main (sha256:c99e462d9ce953ded78f77c531ecbcfdfdfa0e46131c207db9c066f82c96a0d4)...done
sudo: preserving the entire environment is not supported, '-E' is ignored
unpacking ghcr.io/kunami264/projeto-final-devops/service-orders:main (sha256:02d6fef6267638f6bc9248f85b0f3597a219ce7bfd19833ccd5641fbef8b638a)...done
sudo: preserving the entire environment is not supported, '-E' is ignored
unpacking ghcr.io/kunami264/projeto-final-devops/web:main (sha256:875e4c99883991e6697e888ed24997f7aaecd8611f14c25ecbcad09d77d45e65)...done
===== [STG→PRD] Certificado TLS de PRD no cluster =====
secret/projeto-final-tls created
secret/projeto-final-tls created
===== [STG] ✅ PRD está pronto a subir: make run-prd =====
daniel-almeida@daniel-ubuntu:~/Transferências/ProjetoFinal$