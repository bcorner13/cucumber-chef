################################################################################
#
#      Author: Stephen Nelson-Smith <stephen@atalanta-systems.com>
#      Author: Zachary Patten <zachary@jovelabs.com>
#   Copyright: Copyright (c) 2011-2013 Atalanta Systems Ltd
#     License: Apache License, Version 2.0
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
################################################################################

module Cucumber
  module Chef

    class ContainerError < Error; end

    class Container < ZTK::DSL::Base
      belongs_to :ecosystem, :class_name => "Cucumber::Chef::Ecosystem"

      attribute :name
      attribute :ip
      attribute :mac
      attribute :persist
      attribute :distro
      attribute :release
      attribute :arch
      attribute :roles
      attribute :chef_client
    end

  end
end

################################################################################
