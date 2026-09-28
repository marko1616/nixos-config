#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float viewWidth;
    float viewHeight;
    float bodyWidth;
    float barOverlap;
    float cornerRadius;
    float smoothing;
    float gap;
    float progress;
    vec4 fillColor;
    vec4 outlineColor;
    float outlineWidth;
};

float sdRoundedBox(vec2 point, vec2 center, vec2 halfSize, float radius) {
    vec2 q = abs(point - center) - halfSize + vec2(radius);
    return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
}

float smoothUnion(float a, float b, float radius) {
    float h = clamp(0.5 + 0.5 * (b - a) / radius, 0.0, 1.0);
    return mix(b, a, h) - radius * h * (1.0 - h);
}

void main() {
    vec2 pixel = qt_TexCoord0 * vec2(viewWidth, viewHeight);
    float morph = clamp(progress, 0.0, 1.0);

    // The first SDF is the full bar's lower half-plane, not a copy of the
    // triggering pill. The second is a panel that grows out of that plane.
    // Extra transparent width around the body leaves room for both shoulders.
    // At progress 0 the body sits farther than the smoothing radius inside
    // the bar plane, so only the already-painted bar remains before unmapping.
    float retractedTop = barOverlap - smoothing - 2.0;
    float bodyTop = mix(retractedTop, gap, progress);
    float fullBodyHeight = viewHeight - gap;
    float bodyHeight = max(1.0, fullBodyHeight * morph);
    float bodyScaleX = 0.92 + 0.08 * morph;
    vec2 bodyHalf = vec2(bodyWidth * bodyScaleX * 0.5, bodyHeight * 0.5);
    vec2 bodyCenter = vec2(viewWidth * 0.5, bodyTop + bodyHeight * 0.5);
    float effectiveRadius = min(cornerRadius, min(bodyHalf.x, bodyHalf.y));

    float bodyDistance = sdRoundedBox(pixel, bodyCenter, bodyHalf, effectiveRadius);
    float barDistance = pixel.y - barOverlap;
    float distanceToShape = smoothUnion(bodyDistance, barDistance, smoothing);

    float antialias = max(fwidth(distanceToShape), 0.75);
    float coverage = 1.0 - smoothstep(-antialias, antialias, distanceToShape);
    float inner = 1.0 - smoothstep(-outlineWidth - antialias,
                                   -outlineWidth + antialias, distanceToShape);
    float stroke = max(0.0, coverage - inner);
    // Premultiplied output: the border follows the union's outside contour,
    // including the concave shoulders, rather than crossing its neck.
    fragColor = vec4(fillColor.rgb * fillColor.a * inner
                   + outlineColor.rgb * outlineColor.a * stroke,
                     fillColor.a * inner + outlineColor.a * stroke) * qt_Opacity;
}
