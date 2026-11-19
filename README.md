# Dockerized Diagnostic CLI

A lightweight, containerized Linux diagnostic
command-line application developed for DevOps
Practical Assignment 2.

The application is implemented in Bash and supports
Linux system diagnostics, disk inspection, network
connectivity testing and command-line help.

No cloud infrastructure or credentials are required.

## Features

- Linux system information
- CPU and memory information
- Filesystem usage reporting
- DNS resolution
- Network interface information
- ICMP connectivity testing
- Input validation
- Predictable exit codes
- Automated health checks
- Docker and Docker Compose support
- Automated container testing

## Project structure

```text
.
├── app/
│   ├── diagnostic.sh
│   └── health-check.sh
├── Dockerfile
├── compose.yaml
├── .dockerignore
├── .gitignore
├── test.sh
├── grade.sh
└── README.md
```

## Requirements

For containerized execution:

- Linux or another supported Docker host
- Docker Engine with a working daemon
- Docker Compose plugin

For direct Bash execution:

- Bash
- Standard Linux utilities
- procps, hostname, coreutils, awk and getent
- iproute2 and iputils-ping for network diagnostics

An internet connection may be required to download
the base image and install packages during the
initial Docker build.

## Installation

Clone the GitHub repository:

```bash
git clone <repository-url>
cd devops-assignment-2-diagnostic-cli
```

Replace `<repository-url>` with the published
GitHub repository URL.

Build the Docker image:

```bash
docker build -t diagnostic-tool:local .
```

## CLI usage

Show help:

```bash
docker run --rm diagnostic-tool:local help
```

System information:

```bash
docker run --rm diagnostic-tool:local system
```

Disk information:

```bash
docker run --rm diagnostic-tool:local disk
```

Network diagnostics:

```bash
docker run --rm diagnostic-tool:local network localhost
docker run --rm diagnostic-tool:local network example.com
```

The network command requires exactly one hostname
or IP address.

## Docker Compose usage

Validate the configuration:

```bash
docker compose config
```

Run supported commands:

```bash
docker compose run --rm diagnostic help
docker compose run --rm diagnostic system
docker compose run --rm diagnostic disk
docker compose run --rm diagnostic network localhost
```

Docker Compose automatically builds the image when
necessary.

## Direct Bash usage

The diagnostic CLI also runs without Docker
when the required Linux utilities are available.

```bash
./app/diagnostic.sh help
./app/diagnostic.sh system
./app/diagnostic.sh disk
./app/diagnostic.sh network localhost
```

## Exit codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Operational or connectivity failure |
| 2 | Invalid command or arguments |

Missing commands, unexpected arguments and malformed
hostnames are rejected with exit code 2.

A failed DNS resolution or blocked ICMP probe may
return exit code 1.

## Automated testing

The student test suite covers:

1. Help
2. System information
3. Disk information
4. Invalid commands
5. Missing network host
6. Invalid hostname
7. Unexpected system arguments
8. Unexpected disk arguments
9. Unexpected help arguments
10. Extra network arguments
11. Container health checks
12. Docker Compose validation
13. Docker Compose execution
14. Localhost DNS resolution
15. Non-root execution

Run:

```bash
./test.sh
```

The test suite builds the image automatically
if the required local image does not exist.

## Health checks

Run the application health-check script locally:

```bash
./app/health-check.sh
```

Run it directly inside Docker:

```bash
docker run --rm \
  --entrypoint /opt/diagnostic/app/health-check.sh \
  diagnostic-tool:local
```

The Dockerfile also defines a HEALTHCHECK instruction.

Because this is a short-lived CLI application,
the health-check script is most useful when run
explicitly or when the image is reused in a
long-running container.

## Instructor grading

Run the supplied assignment grading checks:

```bash
./grade.sh
```

The grading script validates project structure,
Bash syntax, executable permissions, Dockerfile,
Docker image builds, CLI commands, Compose
configuration and the automated test suite.

## Docker security practices

- Minimal Debian base image
- Only necessary OS packages installed
- No hardcoded credentials
- Non-root runtime UID 10001
- Read-only filesystem through Compose
- No-new-privileges through Compose
- Unnecessary files excluded by .dockerignore
- No application ports published

## Development workflow

Implementation work is organized into meaningful
Git commits and merged feature branches.

Development stages:

- Diagnostic CLI implementation
- Health-check implementation
- Docker containerization
- Automated testing
- Final validation and documentation

## Assumptions and limitations

- The application targets a Linux environment.
- Container system information reflects the
  container environment and shared host kernel.
- Docker container disk information describes
  the filesystem visible inside the container,
  not every host filesystem.
- DNS and ICMP access depend on network policy.
- Some networks block ICMP traffic.
- A connectivity failure is not necessarily
  a defect in the diagnostic script.
- Container identity may be displayed as numeric
  UID 10001 when no passwd entry is configured.
- No cloud deployment is required.
