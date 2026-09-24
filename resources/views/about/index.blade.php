@extends('layouts.librenmsv1')

@section('title', __('About'))

@section('content')
<div class="modal fade" id="git_log" tabindex="-1" role="dialog" aria-labelledby="git_log_label" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
                <h4 class="modal-title" id="myModalLabel">{{ __('Local git log') }}</h4>
            </div>
            <div class="modal-body">
                <pre>{!! $git_log !!}</pre>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-default" data-dismiss="modal">{{ __('Close') }}</button>
            </div>
        </div>
    </div>
</div>

<div class="container-fluid">
    <div class="row">
        <div class="col-md-6">

            <div class="ahuva-about-hero">
                <img class="ahuva-on-light" src="{{ asset('images/ahuva_logo_light.png') }}" alt="Ahuva NMS">
                <img class="ahuva-on-dark" src="{{ asset('images/ahuva_logo_dark.png') }}" alt="Ahuva NMS">
            </div>
            <h2 class="ahuva-accent">Ahuva NMS</h2>
            <p class="lead">Ahuva NMS developed by Ahuva Enosh Varma</p>
            <p><em>Elevating Tech, Empowering Lives</em></p>
            <h3>{{ __('An autodiscovering network monitoring system') }}</h3>
            <table class='table table-condensed table-hover'>
                <tr>
                    <td><b>{{ __('Version') }}</b></td>
                    <td>{{ $version_local }}<span id='version_date' style="display: none;">{{ $git_date }}</span></td>
                </tr>
                <tr>
                    <td><b>{{ __('Database Schema') }}</b></td>
                    <td>{{ $db_schema }}</td>
                </tr>
                <tr>
                    <td><b>{{ __('Web Server') }}</b></td>
                    <td>{{ $version_webserver }}</td>
                </tr>
                <tr>
                    <td><a target="_blank" href="https://www.php.net/"><b>{{ __('PHP') }}</b></a></td>
                    <td>{{ $version_php }}</td>
                </tr>
                <tr>
                    <td><a target="_blank" href="https://www.python.org/"><b>{{ __('Python') }}</b></a></td>
                    <td>{{ $version_python }}</td>
                </tr>
                <tr>
                    <td><b>{{ __('Database') }}</b></td>
                    <td>{{ $version_database }}</td>
                </tr>
                <tr>
                    <td><a target="_blank" href="https://laravel.com/"><b>{{ __('Laravel') }}</b></a></td>
                    <td>{{ $version_laravel }}</td>
                </tr>
                <tr>
                    <td><a target="_blank" href="https://oss.oetiker.ch/rrdtool/"><b>{{ __('RRDtool') }}</b></a></td>
                    <td>{{ $version_rrdtool }}</td>
                </tr>
                <tr>
                    <td><a target="_blank" href="https://www.net-snmp.org/"><b>{{ __('Net-SNMP') }}</b></a></td>
                    <td>{{ $version_netsnmp }}</td>
                </tr>
            </table>

          <h3>{{ __('Support') }}</h3>
          <p>
            {{ __('For issues, support and customisation, contact:') }}<br />
            <b>Enosh Varma</b> &ndash; <a href="mailto:varmaenosh@gmail.com">varmaenosh@gmail.com</a>
            <br />
            <a href="#" data-toggle="modal" data-target="#git_log">{{ __('Local git log') }}</a>
          </p>

      </div>
      <div class="col-md-6">

        <h3>{{ __('Statistics') }}</h3>

        <table class='table table-condensed'>


            <tr>
                <td><i class='fa fa-fw fa-server fa-lg icon-theme' aria-hidden='true'></i> <b>{{ __('Devices') }}</b></td>
                <td class='text-right'>{{ $stat_devices }}</td>
                <td><i class='fa fa-fw fa-link fa-lg icon-theme' aria-hidden='true'></i> <b>{{ __('Ports') }}</b></td>
                <td class='text-right'>{{ $stat_ports }}</td>
            </tr>
            <tr>
                <td><i class='fa fa-fw fa-battery-empty fa-lg icon-theme' aria-hidden='true'></i> <b>{{ __('IPv4 Addresses') }}</b></td>
                <td class='text-right'>{{ $stat_ipv4_addy }}</td>
                <td><i class='fa fa-fw fa-battery-empty fa-lg icon-theme' aria-hidden='true'></i> <b>{{ __('IPv4 Networks') }}</b></td>
                <td class='text-right'>{{ $stat_ipv4_nets }}</td>
            </tr>
            <tr>
                <td><i class='fa fa-fw fa-battery-full fa-lg icon-theme' aria-hidden='true'></i> <b>{{ __('IPv6 Addresses') }}</b></td>
                <td class='text-right'>{{ $stat_ipv6_addy }}</td>
                <td><i class='fa fa-fw fa-battery-full fa-lg icon-theme' aria-hidden='true'></i> <b>{{ __('IPv6 Networks') }}</b></td>
                <td class='text-right'>{{ $stat_ipv6_nets }}</td>
            </tr>
            <tr>
                <td><i class='fa fa-fw fa-cogs fa-lg icon-theme' aria-hidden='true'></i> <b>{{ __('Services') }}</b></td>
                <td class='text-right'>{{ $stat_services }}</td>
                <td><i class='fa fa-fw fa-cubes fa-lg icon-theme' aria-hidden='true'></i> <b>{{ __('Applications') }}</b></td>
                <td class='text-right'>{{ $stat_apps }}</td>
            </tr>
            <tr>
                <td><i class='fa fa-fw fa-microchip fa-lg icon-theme' aria-hidden='true'></i> <b>{{ __('Processors') }}</b></td>
                <td class='text-right'>{{ $stat_processors }}</td>
                <td><i class='fa-fw fas fa-memory fa-lg icon-theme' aria-hidden='true'></i> <b>{{ __('Memory') }}</b></td>
                <td class='text-right'>{{ $stat_memory }}</td>
            </tr>
            <tr>
                <td><i class='fa fa-fw fa-database fa-lg icon-theme' aria-hidden='true'></i> <b>{{ __('Storage') }}</b></td>
                <td class='text-right'>{{ $stat_storage }}</td>
                <td><i class='fa fa-fw fa-hdd-o fa-lg icon-theme' aria-hidden='true'></i> <b>{{ __('Disk I/O') }}</b></td>
                <td class='text-right'>{{ $stat_diskio }}</td>
            </tr>
            <tr>
                <td><i class='fa fa-fw fa-cube fa-lg icon-theme' aria-hidden='true'></i> <b>{{ __('HR-MIB') }}</b></td>
                <td class='text-right'>{{ $stat_hrdev }}</td>
                <td><i class='fa fa-fw fa-cube fa-lg icon-theme' aria-hidden='true'></i> <b>{{ __('Entity-MIB') }}</b></td>
                <td class='text-right'>{{ $stat_entphys }}</td>
            </tr>
            <tr>
                <td><i class='fa fa-fw fa-clone fa-lg icon-theme' aria-hidden='true'></i> <b>{{ __('Alert Log Entries') }}</b></td>
                <td class='text-right'>{{ $stat_alertlogs }}</td>
                <td><i class='fa fa-fw fa-bookmark fa-lg icon-theme' aria-hidden='true'></i> <b>{{ __('Eventlog Entries') }}</b></td>
                <td class='text-right'>{{ $stat_events }}</td>
            </tr>
            <tr>
                <td><i class='fa fa-fw fa-dashboard fa-lg icon-theme' aria-hidden='true'></i> <b>{{ __('sensors.title') }}</b></td>
                <td class='text-right'>{{ $stat_sensors }}</td>
                <td><i class='fa fa-fw fa-wifi fa-lg icon-theme' aria-hidden='true'></i> <b>{{ __('Wireless Sensors') }}</b></td>
                <td class='text-right'>{{ $stat_wireless }}</td>
            </tr>
            <tr>
                <td><i class='fa fa-fw fa-print fa-lg icon-theme' aria-hidden='true'></i> <b>{{ __('Toner') }}</b></td>
                <td class='text-right'>{{ $stat_toner }}</td>
                <td><i class='fa fa-fw fa-code-fork fa-lg icon-theme' aria-hidden='true'></i> <b>{{ __('QoS Queues') }}</b></td>
                <td class='text-right'>{{ $stat_qos }}</td>
            </tr>
        </table>

        <h3>{{ __('License') }}</h3>
        <pre>
Ahuva NMS: Copyright (C) 2026-{{ date('Y') }} Ahuva Enosh Varma
Portions: Copyright (C) 2006-{{ date('Y') }} their respective authors
(see AUTHORS.md and LICENSE.txt in the installation directory)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <a target="_blank" href="https://www.gnu.org/licenses/">https://www.gnu.org/licenses/</a>.</pre>

        </div>
    </div>
</div>
@endsection

@section('scripts')
<script>
    var ver_date = $('#version_date');
    if (ver_date.text()) {
        ver_date.text(' - '.concat(moment(ver_date.text()))).show();
    }
</script>
@endsection
