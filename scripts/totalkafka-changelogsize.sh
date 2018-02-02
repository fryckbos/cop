find 'data/kafka/data' -regex '.*changelog.*' -print0 | du --files0-from=- -ch | sort -h
