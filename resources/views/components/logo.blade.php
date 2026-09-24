@if($image)
    {{-- Include svgs inline so they can use currentColor for light/dark mode, but only if they are hosted on the same server (browser will reject it otherwise) --}}
    @if($is_svg)
        <svg {{ $attributes->class(['tw:dark:text-white', 'tw:text-gray-600']) }} style="max-height: 64px">
            <use href="{{ asset($image) }}"></use>
        </svg>
    @else
        <img {{ $attributes }} src="{{ asset($image) }}" alt="{{ $text }}">
    @endif
@else
    {{-- Ahuva NMS logo: black artwork for light theme, white artwork for dark theme --}}
    <span {{ $attributes->class(['ahuva-logo'])->class($responsive ? ['tw:hidden', $logo_show_class] : []) }}>
        <img class="ahuva-on-light" src="{{ asset('images/ahuva_logo_nav_light.png') }}" alt="{{ $text }}">
        <img class="ahuva-on-dark" src="{{ asset('images/ahuva_logo_nav_dark.png') }}" alt="{{ $text }}">
        <span class="ahuva-logo-nms">NMS</span>
    </span>
    @if($responsive)
    <span {{ $attributes->class(['ahuva-logo', 'tw:inline-block', $logo_hide_class]) }}>
        <img class="ahuva-on-light" src="{{ asset('images/ahuva_icon_light.png') }}" alt="{{ $text }}">
        <img class="ahuva-on-dark" src="{{ asset('images/ahuva_icon_dark.png') }}" alt="{{ $text }}">
    </span>
    @endif
@endif
