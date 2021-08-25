#!/usr/bin/env node

/*
This script will download parameters from PARAMETER STORE.
This template needs two command line args to work.
  1) A filename where the script will put the variables -- DefaultVariables.txt (could be relative or absolut path)
  2) The BeginsWith parameter, with this we will decide wich parameter pull, -- /DEV/   /STAGING/   /DEFAULT
*/
var AWS = require('aws-sdk');
const fs = require('fs');
var OUTPUT      = process.argv[2] // ssm_source
var OUTPUTENV   = process.argv[3] // .env
var BEGINSWITH  = process.argv[4] // ex. /recognize/patagonia
var REGION      = process.argv[5] // us-west-1
var ssm = new AWS.SSM({region:REGION});

var params = {
  MaxResults: 10,
  WithDecryption: true,
  Path: BEGINSWITH
};

function collectParameters(err, data) {
  if (err) console.log(err, err.stack); // an error occurred
  else {
    for (var parameter in data.Parameters) {
      setEnvironmentVariables(data.Parameters[parameter])
    }

    if (typeof data.NextToken !== 'undefined') {
      params["NextToken"]=data.NextToken
      ssm.getParametersByPath(params, collectParameters);
    }
  }
}

function setEnvironmentVariables(parameter) {
  fs.appendFile(OUTPUT, 'export ' + parameter.Name.split("/")[3] + '="' + parameter.Value + "\"\n" , function (err) {
    if (err) throw err;
  });
  fs.appendFile(OUTPUTENV, parameter.Name.split("/")[3] + '="' + parameter.Value + "\"\n" , function (err) {
    if (err) throw err;
  });
}

ssm.getParametersByPath(params, collectParameters);
