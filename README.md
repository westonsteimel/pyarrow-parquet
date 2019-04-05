## Description

Produces python wheels for [Apache Arrow](https://github.com/apache/arrow) stripping out all but support for parquet.  
Useful for fitting into AWS Lambda functions.

## Building

Produces wheel files in dist/

```bash
PYTHON_VERSION=3.6 ARROW_VERSION=0.13.0 ./prepare_wheel.sh
```
