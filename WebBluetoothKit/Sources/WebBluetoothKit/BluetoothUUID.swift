import CoreBluetooth
import Foundation

enum BluetoothUUID {
    
    static func canonicalString(_ uuid: CBUUID) -> String {
        let s = uuid.uuidString.lowercased()
        switch s.count {
        case 4:
            return "0000\(s)-0000-1000-8000-00805f9b34fb"
        case 8:
            return "\(s)-0000-1000-8000-00805f9b34fb"
        default:
            return s
        }
    }
    
    static func parse(_ value: Any) -> CBUUID? {
        if let number = numberValue(value) {
            return CBUUID(string: String(format: "%08X", number))
        }
        
        guard let string = value as? String else { return nil }
        
        if let assigned = assignedServices[string] ?? assignedCharacteristics[string] ?? assignedDescriptors[string] {
            return CBUUID(string: String(format: "%04X", assigned))
        }
        
        let lowered = string.lowercased()
        let uuidPattern = "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"
        if lowered.range(of: uuidPattern, options: .regularExpression) != nil {
            return CBUUID(string: lowered)
        }
        
        if lowered.range(of: "^[0-9a-f]{1,8}$", options: .regularExpression) != nil {
            return CBUUID(string: lowered)
        }
        
        return nil
    }
    
    private static func numberValue(_ value: Any) -> UInt32? {
        if let number = value as? NSNumber {
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return nil
            }
            return number.uint32Value
        }
        if let value = value as? UInt32 { return value }
        if let value = value as? Int, value >= 0 { return UInt32(value) }
        if let value = value as? Int64, value >= 0, value <= Int64(UInt32.max) { return UInt32(value) }
        return nil
    }
}

enum GATTAccess {
    case read
    case write
}

enum GATTBlocklist {
    
    static func isBlocked(_ uuid: CBUUID, access: GATTAccess) -> Bool {
        guard let status = entries[BluetoothUUID.canonicalString(uuid)] else { return false }
        switch access {
        case .read:
            return status.contains(.excludeReads)
        case .write:
            return status.contains(.excludeWrites)
        }
    }
    
    private struct Status: OptionSet {
        let rawValue: Int
        static let excludeReads = Status(rawValue: 1 << 0)
        static let excludeWrites = Status(rawValue: 1 << 1)
        static let exclude: Status = [.excludeReads, .excludeWrites]
    }
    
    private static let entries: [String: Status] = [
        "00001812-0000-1000-8000-00805f9b34fb": .exclude,
        "00001530-1212-efde-1523-785feabcd123": .exclude,
        "f000ffc0-0451-4000-b000-000000000000": .exclude,
        "00060000-0000-1000-8000-00805f9b34fb": .exclude,
        "0000fffd-0000-1000-8000-00805f9b34fb": .exclude,
        "00002a02-0000-1000-8000-00805f9b34fb": .excludeWrites,
        "00002a03-0000-1000-8000-00805f9b34fb": .exclude,
        "00002a25-0000-1000-8000-00805f9b34fb": .exclude,
        "00002902-0000-1000-8000-00805f9b34fb": .excludeWrites,
        "00002903-0000-1000-8000-00805f9b34fb": .excludeWrites,
    ]
}

extension BluetoothUUID {
    
    static let assignedServices: [String: UInt16] = [
        "alert_notification": 0x1811,
        "automation_io": 0x1815,
        "battery_service": 0x180F,
        "blood_pressure": 0x1810,
        "body_composition": 0x181B,
        "bond_management": 0x181E,
        "continuous_glucose_monitoring": 0x181F,
        "current_time": 0x1805,
        "cycling_power": 0x1818,
        "cycling_speed_and_cadence": 0x1816,
        "device_information": 0x180A,
        "environmental_sensing": 0x181A,
        "fitness_machine": 0x1826,
        "generic_access": 0x1800,
        "generic_attribute": 0x1801,
        "glucose": 0x1808,
        "health_thermometer": 0x1809,
        "heart_rate": 0x180D,
        "http_proxy": 0x1823,
        "human_interface_device": 0x1812,
        "immediate_alert": 0x1802,
        "indoor_positioning": 0x1821,
        "internet_protocol_support": 0x1820,
        "link_loss": 0x1803,
        "location_and_navigation": 0x1819,
        "mesh_provisioning": 0x1827,
        "mesh_proxy": 0x1828,
        "next_dst_change": 0x1807,
        "object_transfer": 0x1825,
        "phone_alert_status": 0x180E,
        "pulse_oximeter": 0x1822,
        "reconnection_configuration": 0x1829,
        "reference_time_update": 0x1806,
        "running_speed_and_cadence": 0x1814,
        "scan_parameters": 0x1813,
        "transport_discovery": 0x1824,
        "tx_power": 0x1804,
        "user_data": 0x181C,
        "weight_scale": 0x181D
    ]
    
    static let assignedCharacteristics: [String: UInt16] = [
        "aerobic_heart_rate_lower_limit": 0x2A7E,
        "aerobic_heart_rate_upper_limit": 0x2A84,
        "aerobic_threshold": 0x2A7F,
        "age": 0x2A80,
        "aggregate": 0x2A5A,
        "alert_category_id": 0x2A43,
        "alert_category_id_bit_mask": 0x2A42,
        "alert_level": 0x2A06,
        "alert_notification_control_point": 0x2A44,
        "alert_status": 0x2A3F,
        "altitude": 0x2AB3,
        "anaerobic_heart_rate_lower_limit": 0x2A81,
        "anaerobic_heart_rate_upper_limit": 0x2A82,
        "anaerobic_threshold": 0x2A83,
        "analog": 0x2A58,
        "analog_output": 0x2A59,
        "apparent_wind_direction": 0x2A73,
        "apparent_wind_speed": 0x2A72,
        "barometric_pressure_trend": 0x2AA3,
        "battery_level": 0x2A19,
        "battery_level_state": 0x2A1B,
        "battery_power_state": 0x2A1A,
        "blood_pressure_feature": 0x2A49,
        "blood_pressure_measurement": 0x2A35,
        "body_composition_feature": 0x2A9B,
        "body_composition_measurement": 0x2A9C,
        "body_sensor_location": 0x2A38,
        "bond_management_control_point": 0x2AA4,
        "bond_management_feature": 0x2AA5,
        "boot_keyboard_input_report": 0x2A22,
        "boot_keyboard_output_report": 0x2A32,
        "boot_mouse_input_report": 0x2A33,
        "cgm_feature": 0x2AA8,
        "cgm_measurement": 0x2AA7,
        "cgm_session_run_time": 0x2AAB,
        "cgm_session_start_time": 0x2AAA,
        "cgm_specific_ops_control_point": 0x2AAC,
        "cgm_status": 0x2AA9,
        "cross_trainer_data": 0x2ACE,
        "csc_feature": 0x2A5C,
        "csc_measurement": 0x2A5B,
        "current_time": 0x2A2B,
        "cycling_power_control_point": 0x2A66,
        "cycling_power_feature": 0x2A65,
        "cycling_power_measurement": 0x2A63,
        "cycling_power_vector": 0x2A64,
        "database_change_increment": 0x2A99,
        "date_of_birth": 0x2A85,
        "date_of_threshold_assessment": 0x2A86,
        "date_time": 0x2A08,
        "day_date_time": 0x2A0A,
        "day_of_week": 0x2A09,
        "descriptor_value_changed": 0x2A7D,
        "dew_point": 0x2A7B,
        "digital": 0x2A56,
        "digital_output": 0x2A57,
        "dst_offset": 0x2A0D,
        "elevation": 0x2A6C,
        "email_address": 0x2A87,
        "exact_time_100": 0x2A0B,
        "exact_time_256": 0x2A0C,
        "fat_burn_heart_rate_lower_limit": 0x2A88,
        "fat_burn_heart_rate_upper_limit": 0x2A89,
        "firmware_revision_string": 0x2A26,
        "first_name": 0x2A8A,
        "fitness_machine_control_point": 0x2AD9,
        "fitness_machine_feature": 0x2ACC,
        "fitness_machine_status": 0x2ADA,
        "five_zone_heart_rate_limits": 0x2A8B,
        "floor_number": 0x2AB2,
        "gap.appearance": 0x2A01,
        "gap.central_address_resolution": 0x2AA6,
        "gap.device_name": 0x2A00,
        "gap.peripheral_preferred_connection_parameters": 0x2A04,
        "gap.peripheral_privacy_flag": 0x2A02,
        "gap.reconnection_address": 0x2A03,
        "gatt.service_changed": 0x2A05,
        "gender": 0x2A8C,
        "glucose_feature": 0x2A51,
        "glucose_measurement": 0x2A18,
        "glucose_measurement_context": 0x2A34,
        "gust_factor": 0x2A74,
        "hardware_revision_string": 0x2A27,
        "heart_rate_control_point": 0x2A39,
        "heart_rate_max": 0x2A8D,
        "heart_rate_measurement": 0x2A37,
        "heat_index": 0x2A7A,
        "height": 0x2A8E,
        "hid_control_point": 0x2A4C,
        "hid_information": 0x2A4A,
        "hip_circumference": 0x2A8F,
        "http_control_point": 0x2ABA,
        "http_entity_body": 0x2AB9,
        "http_headers": 0x2AB7,
        "http_status_code": 0x2AB8,
        "https_security": 0x2ABB,
        "humidity": 0x2A6F,
        "ieee_11073-20601_regulatory_certification_data_list": 0x2A2A,
        "indoor_bike_data": 0x2AD2,
        "indoor_positioning_configuration": 0x2AAD,
        "intermediate_cuff_pressure": 0x2A36,
        "intermediate_temperature": 0x2A1E,
        "irradiance": 0x2A77,
        "language": 0x2AA2,
        "last_name": 0x2A90,
        "latitude": 0x2AAE,
        "ln_control_point": 0x2A6B,
        "ln_feature": 0x2A6A,
        "local_east_coordinate": 0x2AB1,
        "local_north_coordinate": 0x2AB0,
        "local_time_information": 0x2A0F,
        "location_and_speed": 0x2A67,
        "location_name": 0x2AB5,
        "Longitude": 0x2AAF,
        "magnetic_declination": 0x2A2C,
        "Magnetic_flux_density_2D": 0x2AA0,
        "Magnetic_flux_density_3D": 0x2AA1,
        "manufacturer_name_string": 0x2A29,
        "maximum_recommended_heart_rate": 0x2A91,
        "measurement_interval": 0x2A21,
        "model_number_string": 0x2A24,
        "navigation": 0x2A68,
        "network_availability": 0x2A3E,
        "new_alert": 0x2A46,
        "object_action_control_point": 0x2AC5,
        "object_changed": 0x2AC8,
        "object_first_created": 0x2AC1,
        "object_id": 0x2AC3,
        "object_last_modified": 0x2AC2,
        "object_list_control_point": 0x2AC6,
        "object_list_filter": 0x2AC7,
        "object_name": 0x2ABE,
        "object_properties": 0x2AC4,
        "object_size": 0x2AC0,
        "object_type": 0x2ABF,
        "ots_feature": 0x2ABD,
        "plx_continuous_measurement": 0x2A5F,
        "plx_features": 0x2A60,
        "plx_spot_check_measurement": 0x2A5E,
        "pnp_id": 0x2A50,
        "pollen_concentration": 0x2A75,
        "position_2d": 0x2A2F,
        "position_3d": 0x2A30,
        "position_quality": 0x2A69,
        "pressure": 0x2A6D,
        "protocol_mode": 0x2A4E,
        "pulse_oximetry_control_point": 0x2A62,
        "rainfall": 0x2A78,
        "rc_feature": 0x2B1D,
        "rc_settings": 0x2B1E,
        "reconnection_configuration_control_point": 0x2B1F,
        "record_access_control_point": 0x2A52,
        "reference_time_information": 0x2A14,
        "removable": 0x2A3A,
        "report": 0x2A4D,
        "report_map": 0x2A4B,
        "resolvable_private_address_only": 0x2AC9,
        "resting_heart_rate": 0x2A92,
        "ringer_control_point": 0x2A40,
        "ringer_setting": 0x2A41,
        "rower_data": 0x2AD1,
        "rsc_feature": 0x2A54,
        "rsc_measurement": 0x2A53,
        "sc_control_point": 0x2A55,
        "scan_interval_window": 0x2A4F,
        "scan_refresh": 0x2A31,
        "scientific_temperature_celsius": 0x2A3C,
        "secondary_time_zone": 0x2A10,
        "sensor_location": 0x2A5D,
        "serial_number_string": 0x2A25,
        "service_required": 0x2A3B,
        "software_revision_string": 0x2A28,
        "sport_type_for_aerobic_and_anaerobic_thresholds": 0x2A93,
        "stair_climber_data": 0x2AD0,
        "step_climber_data": 0x2ACF,
        "string": 0x2A3D,
        "supported_heart_rate_range": 0x2AD7,
        "supported_inclination_range": 0x2AD5,
        "supported_new_alert_category": 0x2A47,
        "supported_power_range": 0x2AD8,
        "supported_resistance_level_range": 0x2AD6,
        "supported_speed_range": 0x2AD4,
        "supported_unread_alert_category": 0x2A48,
        "system_id": 0x2A23,
        "tds_control_point": 0x2ABC,
        "temperature": 0x2A6E,
        "temperature_celsius": 0x2A1F,
        "temperature_fahrenheit": 0x2A20,
        "temperature_measurement": 0x2A1C,
        "temperature_type": 0x2A1D,
        "three_zone_heart_rate_limits": 0x2A94,
        "time_accuracy": 0x2A12,
        "time_broadcast": 0x2A15,
        "time_source": 0x2A13,
        "time_update_control_point": 0x2A16,
        "time_update_state": 0x2A17,
        "time_with_dst": 0x2A11,
        "time_zone": 0x2A0E,
        "training_status": 0x2AD3,
        "treadmill_data": 0x2ACD,
        "true_wind_direction": 0x2A71,
        "true_wind_speed": 0x2A70,
        "two_zone_heart_rate_limit": 0x2A95,
        "tx_power_level": 0x2A07,
        "uncertainty": 0x2AB4,
        "unread_alert_status": 0x2A45,
        "uri": 0x2AB6,
        "user_control_point": 0x2A9F,
        "user_index": 0x2A9A,
        "uv_index": 0x2A76,
        "vo2_max": 0x2A96,
        "waist_circumference": 0x2A97,
        "weight": 0x2A98,
        "weight_measurement": 0x2A9D,
        "weight_scale_feature": 0x2A9E,
        "wind_chill": 0x2A79
    ]
    
    static let assignedDescriptors: [String: UInt16] = [
        "gatt.characteristic_extended_properties": 0x2900,
        "gatt.characteristic_user_description": 0x2901,
        "gatt.client_characteristic_configuration": 0x2902,
        "gatt.server_characteristic_configuration": 0x2903,
        "gatt.characteristic_presentation_format": 0x2904,
        "gatt.characteristic_aggregate_format": 0x2905,
        "valid_range": 0x2906,
        "external_report_reference": 0x2907,
        "report_reference": 0x2908,
        "number_of_digitals": 0x2909,
        "value_trigger_setting": 0x290A,
        "es_configuration": 0x290B,
        "es_measurement": 0x290C,
        "es_trigger_setting": 0x290D,
        "time_trigger_setting": 0x290E
    ]
}
