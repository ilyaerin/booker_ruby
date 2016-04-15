require 'spec_helper'

describe Booker::Helpers::ActiveSupport do
  let(:timezone_map) do
    {
        '(GMT-12:00) International Date Line West' => 'International Date Line West',
        '(GMT-11:00) Midway Island, Samoa' => 'Samoa',
        '(GMT-10:00) Hawaii' => 'Hawaii',
        '(GMT-09:00) Alaska' => 'Alaska',
        '(GMT-08:00) Tijuana, Baja California' => 'Tijuana',
        '(GMT-08:00) Pacific Time (US & Canada)' => 'Pacific Time (US & Canada)',
        '(GMT-07:00) Chihuahua, La Paz, Mazatlan - New' => 'Chihuahua',
        '(GMT-07:00) Arizona' => 'Arizona',
        '(GMT-07:00) Mountain Time (US & Canada)' => 'Mountain Time (US & Canada)',
        '(GMT-07:00) Chihuahua, La Paz, Mazatlan - Old' => 'Chihuahua',
        '(GMT-06:00) Guadalajara, Mexico City, Monterrey - New' => 'Guadalajara',
        '(GMT-06:00) Central Time (US & Canada)' => 'Central Time (US & Canada)',
        '(GMT-06:00) Central America' => 'Central America',
        '(GMT-06:00) Guadalajara, Mexico City, Monterrey - Old' => 'Guadalajara',
        '(GMT-06:00) Saskatchewan' => 'Saskatchewan',
        '(GMT-05:00) Bogota, Lima, Quito, Rio Branco' => 'Bogota',
        '(GMT-05:00) Indiana (East)' => 'Indiana (East)',
        '(GMT-05:00) Eastern Time (US & Canada)' => 'Eastern Time (US & Canada)',
        '(GMT-04:00) Santiago' => 'Santiago',
        '(GMT-04:00) Caracas, La Paz' => 'Caracas',
        '(GMT-04:00) Atlantic Time (Canada)' => 'Atlantic Time (Canada)',
        '(GMT-04:00) Manaus' => 'Atlantic Time (Canada)',
        '(GMT-03:30) Newfoundland' => 'Newfoundland',
        '(GMT-03:00) Brasilia' => 'Brasilia',
        '(GMT-03:00) Greenland' => 'Greenland',
        '(GMT-03:00) Montevideo' => 'Montevideo',
        '(GMT-03:00) Buenos Aires, Georgetown' => 'Buenos Aires',
        '(GMT-02:00) Mid-Atlantic' => 'Mid-Atlantic',
        '(GMT-01:00) Cape Verde Is.' => 'Cape Verde Is.',
        '(GMT-01:00) Azores' => 'Azores',
        '(GMT) Casablanca, Monrovia, Reykjavik' => 'Casablanca',
        '(GMT) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London' => 'Dublin',
        '(GMT+01:00) West Central Africa' => 'West Central Africa',
        '(GMT+01:00) Sarajevo, Skopje, Warsaw, Zagreb' => 'Sarajevo',
        '(GMT+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna' => 'Amsterdam',
        '(GMT+01:00) Brussels, Copenhagen, Madrid, Paris' => 'Brussels',
        '(GMT+01:00) Belgrade, Bratislava, Budapest, Ljubljana, Prague' => 'Belgrade',
        '(GMT+02:00) Windhoek' => 'Harare',
        '(GMT+02:00) Jerusalem' => 'Jerusalem',
        '(GMT+02:00) Amman' => 'Jerusalem',
        '(GMT+02:00) Beirut' => 'Jerusalem',
        '(GMT+02:00) Harare, Pretoria' => 'Harare',
        '(GMT+02:00) Helsinki, Kyiv, Riga, Sofia, Tallinn, Vilnius' => 'Helsinki',
        '(GMT+02:00) Cairo' => 'Cairo',
        '(GMT+02:00) Minsk' => 'Minsk',
        '(GMT+02:00) Athens, Bucharest, Istanbul' => 'Athens',
        '(GMT+03:00) Moscow, St. Petersburg, Volgograd' => 'Moscow',
        '(GMT+03:00) Nairobi' => 'Nairobi',
        '(GMT+03:00) Kuwait, Riyadh' => 'Kuwait',
        '(GMT+03:00) Tbilisi' => 'Tbilisi',
        '(GMT+03:00) Baghdad' => 'Baghdad',
        '(GMT+03:30) Tehran' => 'Tehran',
        '(GMT+04:00) Caucasus Standard Time' => 'Yerevan',
        '(GMT+04:00) Yerevan' => 'Yerevan',
        '(GMT+04:00) Abu Dhabi, Muscat' => 'Abu Dhabi',
        '(GMT+04:00) Baku' => 'Baku',
        '(GMT+04:30) Kabul' => 'Kabul',
        '(GMT+05:00) Ekaterinburg' => 'Ekaterinburg',
        '(GMT+05:00) Islamabad, Karachi, Tashkent' => 'Islamabad',
        '(GMT+05:30) Sri Jayawardenepura' => 'Sri Jayawardenepura',
        '(GMT+05:30) Chennai, Kolkata, Mumbai, New Delhi' => 'Chennai',
        '(GMT+05:45) Kathmandu' => 'Kathmandu',
        '(GMT+06:00) Almaty, Novosibirsk' => 'Almaty',
        '(GMT+06:00) Astana, Dhaka' => 'Astana',
        '(GMT+06:30) Yangon (Rangoon)' => 'Rangoon',
        '(GMT+07:00) Bangkok, Hanoi, Jakarta' => 'Bangkok',
        '(GMT+07:00) Krasnoyarsk' => 'Krasnoyarsk',
        '(GMT+08:00) Taipei' => 'Taipei',
        '(GMT+08:00) Kuala Lumpur, Singapore' => 'Kuala Lumpur',
        '(GMT+08:00) Irkutsk, Ulaan Bataar' => 'Irkutsk',
        '(GMT+08:00) Beijing, Chongqing, Hong Kong, Urumqi' => 'Beijing',
        '(GMT+08:00) Perth' => 'Perth',
        '(GMT+09:00) Osaka, Sapporo, Tokyo' => 'Osaka',
        '(GMT+09:00) Seoul' => 'Seoul',
        '(GMT+09:00) Yakutsk' => 'Yakutsk',
        '(GMT+09:30) Darwin' => 'Darwin',
        '(GMT+09:30) Adelaide' => 'Adelaide',
        '(GMT+10:00) Hobart' => 'Hobart',
        '(GMT+10:00) Brisbane' => 'Brisbane',
        '(GMT+10:00) Vladivostok' => 'Vladivostok',
        '(GMT+10:00) Guam, Port Moresby' => 'Guam',
        '(GMT+10:00) Canberra, Melbourne, Sydney' => 'Canberra',
        '(GMT+11:00) Magadan, Solomon Is., New Caledonia' => 'Magadan',
        '(GMT+12:00) Fiji, Kamchatka, Marshall Is.' => 'Fiji',
        '(GMT+12:00) Auckland, Wellington' => 'Auckland',
        "(GMT+13:00) Nuku'alofa" => "Nuku'alofa"
    }
  end

  describe 'constants' do
    it 'sets constants to right vals' do
      expect(described_class::BOOKER_TO_ACTIVE_SUPPORT_TIMEZONE).to eq timezone_map
    end
  end

  describe '.to_active_support' do
    it 'returns right active support time zone' do
      expect(described_class.to_active_support("(GMT+13:00) Nuku'alofa")).to eq "Nuku'alofa"
      expect(described_class.to_active_support("(GMT+13:00) foo")).to eq nil
    end
  end

  describe '.booker_timezone_names' do
    it 'returns booker time zone names' do
      expect(described_class.booker_timezone_names).to eq timezone_map.keys
    end
  end
end
