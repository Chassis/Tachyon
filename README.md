# Tachyon

A Chassis extension to install and configure Tachyon on your Chassis server.

Tachyon is a faster than light image resizing service. You can [learn about the
server here](https://github.com/humanmade/tachyon).

You'll also need the [Tachyon WordPress Plugin](https://github.com/humanmade/tachyon-plugin) to take advantage of the service.

## Installation

Via Chassis config:

```
extensions:
  - chassis/nodejs
  - chassis/tachyon
```

Or clone into your extensions directory using git:

```

git clone --recursive git@github.com:Chassis/Tachyon.git tachyon
```

Run `vagrant provision`.

## Configuration options

You can configure the port used by Tachyon in your chassis config file.
```yaml
tachyon:
  port: 1234
```

Check the `local-config.php` for the settings you can define.
