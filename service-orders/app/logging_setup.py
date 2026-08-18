"""
Logging estruturado (JSON) com correlação log ↔ trace.

Cada linha de log inclui o trace_id/span_id do span OpenTelemetry ativo
no momento em que foi emitida (quando existe um). Isto permite dois
sentidos de investigação num incidente:
  - a partir de uma linha de log suspeita, saltar diretamente para o
    trace correspondente no Jaeger (pesquisa por trace_id);
  - a partir de um trace lento/com erro no Jaeger, encontrar todas as
    linhas de log emitidas durante esse pedido em qualquer serviço,
    fazendo grep ao trace_id no agregador de logs (ex.: Loki/ELK).

Sem esta correlação, logs e traces são dois silos que só se cruzam por
timestamp aproximado — o que é lento e pouco fiável em produção sob carga.
"""
import json
import logging

from opentelemetry import trace


class TraceCorrelationFilter(logging.Filter):
    """Injeta trace_id/span_id do span ativo em cada LogRecord."""

    def filter(self, record: logging.LogRecord) -> bool:
        ctx = trace.get_current_span().get_span_context()
        if ctx.is_valid:
            record.trace_id = format(ctx.trace_id, "032x")
            record.span_id = format(ctx.span_id, "016x")
        else:
            record.trace_id = None
            record.span_id = None
        return True


class JsonFormatter(logging.Formatter):
    """Formato JSON de uma linha — pronto para um coletor (Fluent Bit,
    Promtail, etc.) indexar sem regex frágeis."""

    def __init__(self, service_name: str):
        super().__init__()
        self.service_name = service_name

    def format(self, record: logging.LogRecord) -> str:
        payload = {
            "timestamp": self.formatTime(record, "%Y-%m-%dT%H:%M:%S%z"),
            "level": record.levelname,
            "service": self.service_name,
            "logger": record.name,
            "message": record.getMessage(),
            "trace_id": getattr(record, "trace_id", None),
            "span_id": getattr(record, "span_id", None),
        }
        if record.exc_info:
            payload["exception"] = self.formatException(record.exc_info)
        return json.dumps(payload, ensure_ascii=False)


def configure_logging(service_name: str) -> logging.Logger:
    """Substitui a configuração de logging por defeito por um handler
    único, em JSON, com correlação de trace — incluindo para os loggers
    do uvicorn, para que o access log também fique correlacionado."""
    handler = logging.StreamHandler()
    handler.setFormatter(JsonFormatter(service_name))
    handler.addFilter(TraceCorrelationFilter())

    root = logging.getLogger()
    root.handlers = [handler]
    root.setLevel(logging.INFO)

    for noisy_logger in ("uvicorn", "uvicorn.access", "uvicorn.error"):
        target = logging.getLogger(noisy_logger)
        target.handlers = [handler]
        target.propagate = False

    return logging.getLogger(service_name)
