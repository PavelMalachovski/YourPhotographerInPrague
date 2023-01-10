<?php

class Polylang_Theme_Translation_Settings
{
    protected static $settings;

    protected function __construct()
    {
    }

    /**
     * @return false|mixed|null
     */
    public static function getInstance()
    {
        if (empty(self::$settings)) {
            self::$settings = get_option(Polylang_Theme_Translation::SETTINGS_OPTION);
        }
        if (!is_array(self::$settings)) {
            self::$settings = [];
        }
        if (!is_array(self::$settings['themes'])) {
            self::$settings['themes'] = [];
        }
        if (!is_array(self::$settings['plugins'])) {
            self::$settings['plugins'] = [];
        }
        if (!is_array(self::$settings['domains'])) {
            self::$settings['domains'] = ['default'];
        }
        return self::$settings;
    }
}
