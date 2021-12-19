# homebus-netatmo-weather

Publish data from a NetAtmo weather station.

## Installation

```
git clone https://github.com/HomeBusProjects/homebus-netatmo
bundle install
```

## Limitations

The publisher currently assumes only one weather station per account,
and will only publish from the first one found. This may lead to
unexpected and undefined results for accounts with multiple weather stations.

## .env

The `.env` file must contain the following values:

```
NETATMO_CLIENT_USERNAME=example@example.com
NETATMO_CLIENT_PASSWORD=a-strong-password
NETATMO_CLIENT_ID=CLIENT_ID
NETATMO_CLIENT_SECRET=CLIENT_SECRET
```

You must obtain a `CLIENT_ID` and `CLIENT_SECRET` from [https://dev.netatmo.com/apps/](https://dev.netatmo.com/apps/)

## License

This code is published under the [MIT License](https://romkey.mit-license.org).
