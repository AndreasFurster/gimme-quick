#!/bin/bash

pushd $1;
  terraform destroy -auto-approve;

popd;