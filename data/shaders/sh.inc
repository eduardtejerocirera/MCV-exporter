//http://silviojemma.com/public/papers/lighting/spherical-harmonic-lighting.pdf

float3 ResolveSH_Opt(float3 premulCoefficients[9], float3 dir)
{
    float3 result = premulCoefficients[0];
    result += premulCoefficients[1] * dir.y;
    result += premulCoefficients[2] * dir.z;
    result += premulCoefficients[3] * dir.x;
    float3 dirSq = dir * dir;
    result += premulCoefficients[4] * (dir.x * dir.y);
    result += premulCoefficients[5] * (dir.z * dir.y);
    result += premulCoefficients[6] * dirSq.z;
    result += premulCoefficients[7] * (dir.x * dir.z);
    result += premulCoefficients[8] * (dirSq.x - dirSq.y);
    return result;
}