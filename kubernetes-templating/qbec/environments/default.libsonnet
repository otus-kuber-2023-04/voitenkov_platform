
// this file has the param overrides for the default environment
local base = import './base.libsonnet';

base {
  components +: {
    services +: {
      indexData: 'services default\n',
      replicas: 2,
    },
  }
}
