FROM golang:1.9 as build
MAINTAINER Menzo Wijmenga
# Install dep for dependency management
RUN go get github.com/golang/dep/cmd/dep

# Install & Cache dependencies
COPY Gopkg.lock Gopkg.toml /go/src/slurp/
WORKDIR /go/src/slurp
RUN dep ensure -vendor-only

# Add app
COPY . /go/src/slurp
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o slurp .

# Download ca-certificates
FROM alpine:latest as certs
RUN apk --update add ca-certificates

# Put everything together in a clean image.
FROM alpine
WORKDIR /slurp

# Copy slurp binary into PATH
COPY --from=build /go/src/slurp/slurp /bin/slurp

# Add certs.
COPY --from=certs /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

# Add permutations to workdir.
ARG permutations=permutations.json
COPY ${permutations} ./permutations.json

# Run slurp when the container starts
ENTRYPOINT [ "/bin/slurp" ]
