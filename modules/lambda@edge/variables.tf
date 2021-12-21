variable "functions" {
  description = "TODO"
  type = map(object({
    source      = list(object({
      filename = string
      content  = string
    }))
    runtime      = string
    handler      = string
    event_type   = string
    include_body = bool
  }))
}