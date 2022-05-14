# limiter :: a rate-limiting plug

- can be added to the router at any level
- can be re-used multiple times w/ a different configuration (each plug generating its own counter table)
- accepts a configuration when called:

  - supporting different limiting strategies:
    - (required) by header (ex. `X-HAWKU-TOKEN`)
    - (nice to have) by IP
    - (nice to have) by combination of different data (ex. multiple headers and IP)
  - cachex counter table name
  - requests allowed
  - timeframe

- if over the limit, return code `429` with `Retry-After` amount of milliseconds the user should wait to make another request and json with an error message.

- (Nice to have) Support receiving and sending extra headers with the status of the rate-limiting counter:

  - `X-Rate-Limit: 700`
  - `X-Rate-Limit-Remaining: 699`

- Use Cachex to store
  - counter
  - api_user_id_field
  - current_rate
  - last_request_received_at

> assume there's a 1:1 correspondence between the value for X-HAWKU-TOKEN and each client's unique identifier given by api_user_id_field
