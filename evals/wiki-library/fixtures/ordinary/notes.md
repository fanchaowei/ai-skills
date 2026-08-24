# Resilient request notes

A retry policy lets a client repeat a transiently failed request. Retries should be limited to operations that are safe to repeat, use a bounded attempt count, and stop on permanent errors.

Exponential backoff spaces retries farther apart after each failure. Adding random jitter prevents many clients from retrying at the same instant. The retry policy references exponential backoff to determine when the next attempt should happen, while exponential backoff is reusable by other recovery mechanisms.

The retry budget limits the total recovery work. It prevents a retry policy from amplifying an outage and can be shared across callers that use the same downstream service.
