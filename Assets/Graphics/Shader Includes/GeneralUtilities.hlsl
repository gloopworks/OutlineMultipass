float Remap(float input, float inputMin, float inputMax, float outputMin, float outputMax)
{
    return (input - inputMin) / (inputMax - inputMin) * (outputMax - outputMin) + outputMin;
}

float RemapZeroOne(float input, float inputMin, float inputMax)
{
    return Remap(input, inputMin, inputMax, 0.0f, 1.0f);
}