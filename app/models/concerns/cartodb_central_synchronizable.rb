module Concerns
  module CartodbCentralSynchronizable

    def is_a_user?
      return self.is_a?(::User) || self.is_a?(Carto::User)
    end

    def is_an_organization?
      return self.is_a?(::Organization) || self.is_a?(Carto::Organization)
    end

    # This validation can't be added to the model because if a user creation begins at Central we can't know if user is the same or existing
    def validate_credentials_not_taken_in_central
      return true unless self.is_a_user?
      return true unless Cartodb::Central.sync_data_with_cartodb_central?

      central_client = Cartodb::Central.new

      errors.add(:username, "Username taken") if central_client.get_user(self.username)['username'] == self.username
      errors.add(:email, "Email taken") if central_client.get_user(self.email)['email'] == self.email
      errors.empty?
    end

    def create_in_central
      return true unless sync_data_with_cartodb_central?
      if self.is_a_user?
        if organization.present?
          cartodb_central_client.create_organization_user(organization.name, allowed_attributes_to_central(:create))
        else
          CartoDB.notify_debug("User creations at box without organization are not notified to Central", user: self)
        end
      elsif self.is_an_organization?
        raise "Can't create organizations in editor"
      end
      return true
    end

    def update_in_central
      return true unless sync_data_with_cartodb_central?
      if self.is_a_user?
        if organization.present?
          cartodb_central_client.update_organization_user(organization.name, username, allowed_attributes_to_central(:update))
        else
          cartodb_central_client.update_user(username, allowed_attributes_to_central(:update))
        end
      elsif self.is_an_organization?
        cartodb_central_client.update_organization(name, allowed_attributes_to_central(:update))
      end
      return true
    end

    def delete_in_central
      return true unless sync_data_with_cartodb_central?
      if self.is_a_user?
        if organization.nil?
          cartodb_central_client.delete_user(self.username)
        else
          if self.organization.owner && self.organization.owner != self
            cartodb_central_client.delete_organization_user(organization.name, username)
          else
            raise "Can't destroy the organization owner"
          end
        end
      elsif is_an_organization?
        # See Organization#destroy_cascade
        raise "Delete organizations is not allowed" if Carto::Configuration.saas?
        cartodb_central_client.delete_organization(name)
      end
      return true
    end

    def allowed_attributes_from_central(action)
      if is_an_organization?
        case action
        when :create
          %i(name seats viewer_seats quota_in_bytes display_name description website
             discus_shortname twitter_username geocoding_quota map_view_quota
             geocoding_block_price map_view_block_price
             twitter_datasource_enabled twitter_datasource_block_size
             twitter_datasource_block_price twitter_datasource_quota
             google_maps_key google_maps_private_key auth_username_password_enabled
             auth_google_enabled here_isolines_quota here_isolines_block_price
             obs_snapshot_quota obs_snapshot_block_price obs_general_quota
             obs_general_block_price salesforce_datasource_enabled geocoder_provider
             isolines_provider routing_provider engine_enabled builder_enabled
             mapzen_routing_quota mapzen_routing_block_price no_map_logo auth_github_enabled
             password_expiration_in_d inherit_owner_ffs)
        when :update
          %i(seats viewer_seats quota_in_bytes display_name description website
             discus_shortname twitter_username geocoding_quota map_view_quota
             geocoding_block_price map_view_block_price
             twitter_datasource_enabled twitter_datasource_block_size
             twitter_datasource_block_price twitter_datasource_quota
             google_maps_key google_maps_private_key auth_username_password_enabled
             auth_google_enabled here_isolines_quota here_isolines_block_price
             obs_snapshot_quota obs_snapshot_block_price obs_general_quota
             obs_general_block_price salesforce_datasource_enabled geocoder_provider
             isolines_provider routing_provider engine_enabled builder_enabled
             mapzen_routing_quota mapzen_routing_block_price no_map_logo auth_github_enabled
             password_expiration_in_d inherit_owner_ffs)
        end
      elsif is_a_user?
        %i(account_type admin org_admin crypted_password database_host
           database_timeout description disqus_shortname available_for_hire email
           geocoding_block_price geocoding_quota map_view_block_price map_view_quota max_layers
           max_import_file_size max_import_table_row_count max_concurrent_import_count
           name last_name notification organization_id period_end_date private_tables_enabled quota_in_bytes
           sync_tables_enabled table_quota public_map_quota regular_api_key_quota
           twitter_username upgraded_at user_timeout username website soft_geocoding_limit
           batch_queries_statement_timeout twitter_datasource_enabled twitter_datasource_block_size
           twitter_datasource_block_price twitter_datasource_quota soft_twitter_datasource_limit
           google_sign_in last_password_change_date github_user_id google_maps_key google_maps_private_key
           private_maps_enabled here_isolines_quota here_isolines_block_price soft_here_isolines_limit
           obs_snapshot_quota obs_snapshot_block_price soft_obs_snapshot_limit
           obs_general_quota obs_general_block_price soft_obs_general_limit
           mobile_xamarin mobile_custom_watermark mobile_offline_maps
           mobile_gis_extension mobile_max_open_users mobile_max_private_users
           salesforce_datasource_enabled viewer geocoder_provider
           isolines_provider routing_provider engine_enabled builder_enabled
           mapzen_routing_quota mapzen_routing_block_price soft_mapzen_routing_limit no_map_logo
           user_render_timeout database_render_timeout state industry company phone job_role
           password_reset_token password_reset_sent_at maintenance_mode company_employees use_case private_map_quota
           session_salt public_dataset_quota dashboard_viewed_at email_verification_token email_verification_sent_at)
      end
    end

    def allowed_attributes_to_central(action)
      if is_an_organization?
        case action
        when :create
          raise "Can't create organizations from editor"
        when :update
          allowed_attributes = %i(seats viewer_seats display_name description website discus_shortname twitter_username
                                  auth_username_password_enabled auth_google_enabled password_expiration_in_d
                                  inherit_owner_ffs)
          attributes.symbolize_keys.slice(*allowed_attributes)
        end
      elsif is_a_user?
        allowed_attributes = %i(
          account_type admin org_admin crypted_password database_host database_timeout description disqus_shortname
          available_for_hire email geocoding_block_price geocoding_quota map_view_block_price map_view_quota max_layers
          max_import_file_size max_import_table_row_count max_concurrent_import_count name last_name notification
          organization_id period_end_date private_tables_enabled quota_in_bytes sync_tables_enabled table_quota
          public_map_quota regular_api_key_quota twitter_username upgraded_at user_timeout username website
          soft_geocoding_limit twitter_datasource_enabled soft_twitter_datasource_limit google_sign_in
          last_password_change_date github_user_id google_maps_key google_maps_private_key here_isolines_quota
          here_isolines_block_price soft_here_isolines_limit obs_snapshot_quota obs_snapshot_block_price
          soft_obs_snapshot_limit obs_general_quota obs_general_block_price soft_obs_general_limit viewer
          geocoder_provider isolines_provider routing_provider builder_enabled engine_enabled mapzen_routing_quota
          mapzen_routing_block_price soft_mapzen_routing_limit industry company phone job_role password_reset_token
          password_reset_sent_at company_employees use_case private_map_quota session_salt public_dataset_quota
          dashboard_viewed_at email_verification_token email_verification_sent_at
        )
        attrs = attributes.symbolize_keys.slice(*allowed_attributes)
        attrs[:multifactor_authentication_status] = multifactor_authentication_status()
        case action
        when :create
          attrs[:remote_user_id] = id
          attrs.delete(:organization_id)
          return attrs
        when :update
          attrs[:batch_queries_statement_timeout] = batch_queries_statement_timeout()
          attrs
        end
      end
    end

    def set_fields_from_central(params, action)
      return self unless params.present? && action.present?
      self.set(params.slice(*allowed_attributes_from_central(action)))

      if self.is_a_user? && params.has_key?(:password)
        self.password = self.password_confirmation = params[:password]
      end
      self
    end

    def set_relationships_from_central(params = {})
      update_feature_flags(params[:feature_flags]) if params[:feature_flags]
    end

    def sync_data_with_cartodb_central?
      Cartodb::Central.sync_data_with_cartodb_central?
    end

    def cartodb_central_client
      @cartodb_central_client ||= Cartodb::Central.new
    end

    def update_feature_flags(feature_flag_ids)
      self_feature_flags_user.where.not(id: feature_flag_ids).destroy_all

      new_feature_flags_ids = feature_flag_ids - self_feature_flags_user.pluck(:id)
      new_feature_flags_ids.each do |feature_flag_id|
        self_feature_flags_user.create!(feature_flag_id: feature_flag_id)
      end
    end

  end
end
