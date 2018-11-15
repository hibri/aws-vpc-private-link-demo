class AwsAlb < Inspec.resource(1)
	name 'aws_alb'
	desc 'Verifies settings for AWS Elastic Load Balancer'
	example "
	  describe aws_alb('myalb') do
		it { should exist }
	  end
	"
	supports platform: 'aws'
  
	include AwsSingularResourceMixin
	attr_reader :availability_zones, :dns_name, :alb_name, :external_ports,
				:instance_ids, :internal_ports, :security_group_ids,
				:subnet_ids, :vpc_id
  
	def to_så
	  "AWS ALB #{alb_name}"
	end
  
	private
  
	def validate_params(raw_params)
	  validated_params = check_resource_param_names(
		raw_params: raw_params,
		allowed_params: [:alb_name],
		allowed_scalar_name: :alb_name,
		allowed_scalar_type: String,
	  )
  
	  if validated_params.empty?
		raise ArgumentError, 'You must provide a alb_name to aws_alb.'
	  end
  
	  validated_params
	end
  
	def fetch_from_api
	
	  backend = BackendFactory.create(inspec_runner)
		begin
		lbs = backend.describe_load_balancers(names: [alb_name])
		@exists = true
		# Load balancer names are uniq; we will either have 0 or 1 result
		unpack_describe_albs_response(lbs.first)
	  rescue Aws::ElasticLoadBalancing::Errors::LoadBalancerNotFound
			@exists = false
			populate_as_missing
	  end
	end
  
	def unpack_describe_albs_response(lb_struct)
		puts lb_struct.inspect
	  @availability_zones = lb_struct.availability_zones
	  @dns_name = lb_struct.dns_name
	  # @external_ports = lb_struct.listener_descriptions.map { |ld| ld.listener.load_balancer_port }
	  # @instance_ids = lb_struct.instances.map(&:instance_id)
	  # @internal_ports = lb_struct.listener_descriptions.map { |ld| ld.listener.instance_port }
	  @alb_name = lb_struct[:load_balancer_name]
	  @security_group_ids = lb_struct.security_groups
	  # @subnet_ids = lb_struct.subnets
	  @vpc_id = lb_struct.vpc_id
	end
  
	def populate_as_missing
	  @availability_zones = []
	  @external_ports = []
	  @instance_ids = []
	  @internal_ports = []
	  @security_group_ids = []
	  @subnet_ids = []
	end
  
	class Backend
	  class AwsClientApi < AwsBackendBase
			BackendFactory.set_default_backend(self)
			self.aws_client_class = Aws::ElasticLoadBalancingV2::Client
			def describe_load_balancers(query = {})
		
				aws_service_client.describe_load_balancers(query).load_balancers
			end
	  end
	end
end