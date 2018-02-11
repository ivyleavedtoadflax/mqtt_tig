all: up
clean: clean_docker clean_docker_containers
nuke: clean_docker clean_docker_containers nuke_data

up: telegraf.conf
	sudo docker-compose up -d

telegraf.conf: telegraf.template.conf .envrc
	echo "Creating telegraf.conf file"; \
	sed -e "s%\$${MQTT_HOST}%$(MQTT_HOST)%" \
	-e "s/\$${MQTT_PORT}/$(MQTT_PORT)/" \
	-e "s%\$${MQTT_TOPIC}%$(MQTT_TOPIC)%" \
	-e "s/\$${MQTT_USERNAME}/$(MQTT_USERNAME)/" \
	-e "s/\$${MQTT_PASSWORD}/$(MQTT_PASSWORD)/" \
	-e "s/\$${DATABASE}/$(DATABASE)/" \
	-e "s%\$${INFLUXDB_HOST}%$(INFLUXDB_HOST)%" \
	-e "s/\$${INFLUXDB_PORT}/$(INFLUXDB_PORT)/" \
	telegraf.template.conf > telegraf.conf

clean_docker:
	-sudo docker-compose stop && \
	sudo docker-compose down

clean_docker_containers:
	-sudo docker stop influxdb && \
	sudo docker rm influxdb; \
	sudo docker stop telegraf && \
	sudo docker rm telegraf;
	sudo docker stop grafana && \
	sudo docker rm grafana

nuke_data:
	-sudo rm -r /data/grafana /data/influx /data/telegraf

test_mqtt:
	mosquitto_sub -h $(MQTT_HOST)  -p $(MQTT_PORT) \
	-u $(MQTT_USERNAME) -P $(MQTT_PASSWORD) -t '#' 

influxdb_latest:
	sudo docker exec -it influxdb influx \
	-precision rfc3339 -database $(DATABASE) \
	-execute "select last(Pulses) as Pulses, Cost, Night, \
	time from /.*/"
.PHONY: clean test_mqtt influxdb_latest nuke_data clean_docker clean_docker_containers
