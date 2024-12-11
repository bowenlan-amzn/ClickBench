
# Setup Dataset

Create c6a.4xlarge EC2 instance with 1500G EBS volumn

wget <https://artifacts.opensearch.org/releases/core/opensearch/2.18.0/opensearch-min-2.18.0-linux-x64.tar.gz>

Add below in /home/ec2-user/opensearch-2.18.0/config/opensearch.yml

```yaml
network.host: 0.0.0.0
http.port: 9200
discovery.type: single-node
http.max_content_length: 500mb
```

Change the heap size in jvm.options

```sh
-Xms16g
-Xmx16g
```

```sh
ps aux | grep [o]pensearch | grep -v nohup | awk '{print $2}' | xargs kill -9
sudo -u ec2-user nohup /home/ec2-user/opensearch-2.18.0/bin/opensearch >> /dev/null 2>&1 &
tail -f /home/ec2-user/opensearch-2.18.0/logs/opensearch.log
```

```sh
curl -X DELETE "http://localhost:9200/hits"
curl -X PUT "http://localhost:9200/hits?pretty" -H 'Content-Type: application/json' -d @mapping.json
```

## Setup the ClickBench Dataset

```sh
wget https://datasets.clickhouse.com/hits_compatible/hits.json.gz
gzip -d hits.json.gz 

# split into small size so can be bulk ingest to OpenSearch
split -l 2000 hits.json hits_

# add the line for bulk index
for file in hits_*; do 
echo ${file};
sed -e 's/^/{ "index" : { "_index" : "hits"} }\n/' -i ${file}; 
done
# try parallel
ls hits_* | xargs -P 5 -I {} bash -c '
file="{}";
echo ${file};
sed -e 's/^/{ "index" : { "_index" : "hits"} }\n/' -i ${file};
'
```

# Indexing

```sh
# Bulk Ingesting
ls hits_* | xargs -P 5 -I {} bash -c '
file="{}";
echo ${file};
response=$(curl -s -H "Content-Type: application/x-ndjson" -XPOST "http://localhost:9200/_bulk" --data-binary @${file});
if [[ $response == *"\"errors\":false"* ]]; then
    echo "succeed for ${file}";
else
    echo "failed for ${file}";
fi'

# to get an idea how many documents ingested, total should be 99,997,497
curl localhost:9200/_cat/indices?v
```

```sh
# when data loading is finished, to get indexing time and store size run
curl -X GET "http://localhost:9200/hits/_stats?pretty&filter_path=_all.total.indexing.index_time_in_millis,_all.total.store.size_in_bytes"
```

# Query Benchmark

Run `run_opensearch.sh`

Install OpenSearch SQL plugin, run `run_opensearch_sql.sh`. You can download the full distribution and copy over the sql and job-scheduler plugins over.
