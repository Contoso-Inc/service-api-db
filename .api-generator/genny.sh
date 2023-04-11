#!/bin/bash
set -e

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

help()
{
    echo ""
      echo "<The command will allow you to use a spec first approach to developing APIs>"
      echo ""
      echo "Command"
      echo "    genny.sh : used to generate models and controllers based on the cadl specs defined."
      echo ""
      echo "Arguments"
      echo "    --output-dir, -o      The dirctory to generate the API in [default: ./modules]"
      echo "    --cadl-file, -c       Path to the cadl file to generate from [default: main.cadl]"
      echo "    --spec-version, -v    Spec version to generate files for [default: v1]"
      echo ""
      exit 1
}

SHORT=c:,v:,o:h
LONG=cadl_file:,spec_version:,output_dir:help
OPTS=$(getopt -a -n files --options $SHORT --longoptions $LONG -- "$@")

eval set -- "$OPTS"

OUTPUT_DIR='./src/WebApi'
CADL_FILE='main.cadl'
SPEC_VERSION='v1'
while :
do
  case "$1" in
    -o | --output_dir )
      OUTPUT_DIR="$2"
      shift 2
      ;;
    -c | --cadl-file )
      CADL="$2"
      shift 2
      ;;
    -v | --spec-version )
      SPEC_VERSION="$2"
      shift 2
      ;;
    -h | --help)
      help
      ;;
    --)
      shift;
      break
      ;;
    *)
      echo "Unexpected option: $1"
      ;;
  esac
done

## Create the output directory if it doesn't already exist
if [ ! -d $OUTPUT_DIR ]
then
  mkdir -p $OUTPUT_DIR
fi

## initialize the Azure Dev CLI Template
azd init -t $TEMPLATE \
    -l $LOCATION  --subscription $SUBSCRIPTION -b $BRANCH \
    -e $ENVIRONMENT -C $OUTPUT_DIR --no-prompt

## Emit the open api spec from the cadl file
cadl compile $CADL_FILE --output-dir $OUTPUT_DIR/spec --emit @cadl-lang/openapi3

PACKAGE_NAME=$(jq -r '.packageName' "$OUTPUT_DIR/genny.json")

GENERATOR_NAME=$(jq -r '.generatorName' "$OUTPUT_DIR/genny.json")

TEMPLATE_PATH=$(jq -r '.templatePath' "$OUTPUT_DIR/genny.json")

## Generate the Models
openapi-generator-cli generate -g $GENERATOR_NAME \
    -o ./temp -i $OUTPUT_DIR/spec/@cadl-lang/openapi3/openapi.$SPEC_VERSION.json \
    --package-name $PACKAGE_NAME -t $OUTPUT_DIR$TEMPLATE_PATH \
    --global-property=models

## Generate the apis
openapi-generator-cli generate -g $GENERATOR_NAME \
    -o ./temp -i $OUTPUT_DIR/spec/@cadl-lang/openapi3/openapi.$SPEC_VERSION.json \
    --package-name $PACKAGE_NAME -t $OUTPUT_DIR$TEMPLATE_PATH \
    --global-property=apis

## Copy generated files
for MOVABLE in $(jq -c '.movables[]' "$OUTPUT_DIR/genny.json"); do
    FROM=$(echo ${MOVABLE} | jq -r '.from')
    TO=$(echo ${MOVABLE} | jq -r '.to')
    FROM_DIR="./temp$FROM"
    TO_DIR="$OUTPUT_DIR$TO"
    echo "Copying files from ${FROM_DIR} to ${TO_DIR}"

    cp -R "$FROM_DIR/." $TO_DIR
done

## Clean Up temporary files used to generate code
rm -rf ./temp
rm ./openapitools.json
