# Mattermost docker installation

## Running


Example docker command:

	docker run -d \
		--name gandi-dns-update \
		-e API_KEY=your_gandi_api_key \
		-e ZONE=example.com \
		-e RECORD='@ www' \
		-e CRON_PATTERN='*/5 * * * *' \
		layr/gandi-dns-update

