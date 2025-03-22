module "swarm" {
  source           = "../../modules/cloud/aws/compute/swarm"
  private_key_path = "${path.module}/private_key.pem"

}

# import {
#   to = module.swarm.aws_key_pair.deployer_key
#   id = "swarm-key"
# }

output "swarm_ssh_command" {
  value = module.swarm.ssh_command
}

# import {
#   to = module.swarm.aws_instance.my_swarm
#   id = "i-016a568dc54120133"
# }

# import {
#   to = module.swarm.aws_security_group.swarm_sg
#   id = "sg-0ad149e886bf00711"
# }
