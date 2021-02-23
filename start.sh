#!/bin/bash

pushd $1;
  terraform init;
  terraform apply -auto-approve;

  pushd outputs;
    . connect.sh;

  popd;
popd;