module AzureDriver
    class WildVM
    
        attr_reader :id, :name

        def initialize deploy_id, client
            @instance = client.get_virtual_machine deploy_id
            
            @id = deploy_id
            @name = @instance.name
            @location = @instance.location
            @size = @instance.hardware_profile.vm_size
            size = client.get_virtual_machine_size(@size, @location)
            @capacity = {
                :cpu => size.number_of_cores,
                :memory => size.memory_in_mb
            }
        end
        def template
            "NAME=#{@name}\n" \
            "DEPLOY_ID=#{@id}\n" \
            "LOCATION=#{@location}\n" \
            "SIZE=#{@size}\n" \
            "CPU=#{@capacity[:cpu]}\n" \
            "MEMORY=#{@capacity[:memory]}\n" \
            "IMPORTED=\"YES\""
        end
        def template64
            Base64::encode64(template)
        end
    end
end