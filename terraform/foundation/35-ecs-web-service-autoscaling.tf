locals {
  resource_service_web = "service/${aws_ecs_cluster.cluste.name}/${aws_ecs_service.web.name}"
}

resource "aws_appautoscaling_target" "target_web" {
  service_namespace = "ecs"
  resource_id = local.resource_service_web.service_namespace
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity = 1
  max_capacity = 3
}

resource "aws_appautoscaling_policy" "scaling_policy_svc_wep" {
  name = "autoscaling-service-web"
  service_namespace = aws_appautoscaling_target.target_web.service_namespace
  resource_id = aws_appautoscaling_target.target_web.resource_id
  scalable_dimension = aws_appautoscaling_target.target_web.scalable_dimension
  policy_type = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 80
  }
}