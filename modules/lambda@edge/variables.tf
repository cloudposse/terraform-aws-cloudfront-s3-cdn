variable "functions" {
  description = "TODO"
  type = map(object({
    local_path   = string
    runtime      = string
    handler      = string
    event_type   = string
    include_body = bool
  }))
}