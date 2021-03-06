#version $GLSL_VERSION_STR

#pragma vp_entryPoint sim_proj_frag
#pragma vp_location fragment_coloring

#pragma import_defines(SIMVIS_USE_REX)
#pragma import_defines(SIMVIS_PROJECT_ON_PLATFORM)

uniform bool projectorActive;
uniform float projectorAlpha;
uniform sampler2D simProjSampler;
in vec4 simProjTexCoord;
in vec3 simProjToVert_VIEW;
flat in vec3 simProjLookVector_VIEW;
vec3 vp_Normal;

#ifdef SIMVIS_PROJECT_ON_PLATFORM

// for a projector texturing a platform or other model:
void sim_proj_frag(inout vec4 color)
{
  if (projectorActive && simProjTexCoord.q > 0)
  {
    vec4 textureColor = textureProj(simProjSampler, simProjTexCoord);
    color.rgb = mix(color.rgb, textureColor.rgb, textureColor.a * projectorAlpha);
  }
}

#else

// for a projector texturing the terrain:
void sim_proj_frag(inout vec4 color)
{
#ifdef SIMVIS_USE_REX
  vec4 outColor = vec4(0.0);
#else
  vec4 outColor = vec4(color.rgb, 0.0);
#endif

  if (projectorActive)
  {
    vec2 local = simProjTexCoord.st / simProjTexCoord.q; // same as textureProj, but do it manually so we can check extents

    if (clamp(local, 0.0, 1.0) == local) // clip to projected texture domain
    {
      if (dot(simProjLookVector_VIEW, simProjToVert_VIEW) >= 0.0)  // only draw in front of projector (not behind)
      {
        float vis = -dot(normalize(simProjToVert_VIEW), normalize(vp_Normal));  // >=0 is visible; <0 is over the horizon.
        if (vis <= 0)
            discard;

        vec4 textureColor = texture(simProjSampler, local);
        outColor = vec4(textureColor.r, textureColor.g, textureColor.b, textureColor.a * projectorAlpha);
      }
    }
  }
  color = outColor;
}

#endif
