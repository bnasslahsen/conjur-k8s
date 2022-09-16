spring:
  data:
    mongodb:
      uri: {{ secret "mongo-uri" }}
springdoc:
  writer-with-order-by-keys: true
  swagger-ui:
    use-root-path: true