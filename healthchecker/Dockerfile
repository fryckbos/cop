FROM python:3.6

COPY requirements.txt /tmp/
RUN pip install --no-cache-dir -r /tmp/requirements.txt

COPY healthcheck.py /

CMD [ "python", "/healthcheck.py" ]

LABEL com.coscale.monitoring='[{"PluginType":"LOGPLUGIN","Configuration":{"MATCH":["\"/dev/stdout\" \"COUNTER\" \"CoScale HealthCheck Log lines\" \".*\" \"#\"","\"/dev/stdout\" \"COUNTER\" \"CoScale HealthCheck Errors\" \"ERROR\" \"#\""]}}]'