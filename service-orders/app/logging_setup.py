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
