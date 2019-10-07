## Description

Produces python wheels for [Apache Arrow](https://github.com/apache/arrow) stripping out all but support for parquet.  
Useful for fitting into AWS Lambda functions.

## Building

From the root of this repository, run the following, substituting the variables you want to build for:

```bash
docker run --rm -it \
    --env ARROW_VERSION="0.15.0" \
    --env PYTHON_VERSION="3.7" \
    --env UNICODE_WIDTH=16 \
    --shm-size=2g \
    -v $PWD:/io \
    arrowdev/arrow_manylinux1_x86_64_base:latest /io/prepare_wheel.sh
```

Wheels will be output under dist/
