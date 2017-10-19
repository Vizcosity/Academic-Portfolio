#!/bin/bash

expr $(echo $* | sed 's/ / + /g')
exit 0
