resource "aws_cloudwatch_event_rule" "ec2_state_change_rule" {
  name        = "ec2-state-change-rule"
  description = "Triggers Lambda on EC2 instance state changes"
  event_pattern = jsonencode({
    "source": ["aws.ec2"],
    "detail-type": ["EC2 Instance State-change Notification"],
    "detail": {
      "state": ["running", "shutting-down"],
    },
  })
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.ec2_state_change_rule.name
  target_id = "lambda_target"
  arn       = aws_lambda_function.update_asg_ip_to_dns.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_asg_ip_to_dns.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ec2_state_change_rule.arn
}