# ================================
# Build image
# ================================
FROM swift:latest as build
WORKDIR /build
COPY ./Package.* ./
RUN swift package resolve
COPY . .
RUN swift build --enable-test-discovery -c debug -Xswiftc -g

# Run image
FROM vapor/ubuntu:18.04
WORKDIR /run
COPY --from=build /build/.build/debug /run
COPY --from=build /usr/lib/swift/ /usr/lib/swift/
COPY --from=build /build/Public /run/Public
ENTRYPOINT ["./Run"]
