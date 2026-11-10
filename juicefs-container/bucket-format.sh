#!/usr/bin/env bash
juicefs format --storage s3 \
    --bucket http://localhost:9001/tenant-1 \
    --access-key iExld9RyfQj9ZPaKKIOE \
    --secret-key MpngPoGyKxjVxMFuhx07s1aVAX3jDLtk59VbjqNd \
    redis://172.17.0.1:6379/1 \
    juicefs