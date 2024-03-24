spring:
  profiles: 
    active: refreshable
  datasource:
    url: {{ secret "dsn" }}
    username: {{ secret "username" }}
    password: {{ secret "password" }}
  jpa:
    hibernate:
      ddl-auto: update  

management:
  server:
    port: 9090
  endpoints:
    web:
      exposure:
        include: health, refresh

springdoc:
  swagger-ui:
    use-root-path: true
    display-request-duration: true
    tags-sorter: alpha
    
logging:
  level:
    org.cyberark: DEBUG