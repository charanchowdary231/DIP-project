function test_metrics()
% TEST_METRICS Unit test verifying MSE, RMSE, and PSNR calculations.
% Specifically verifies the illustrative arithmetic example published in
% Section VI.B, VI.C, and VI.D of the research paper.

    fprintf('========================================================\n');
    fprintf('  RUNNING UNIT TEST: Mathematical Model & Metric Formulae \n');
    fprintf('========================================================\n\n');

    % Reference test vectors from Section VI.B
    f = [100, 120, 140, 160];
    g = [102, 118, 143, 157];

    % Manual step-by-step arithmetic
    diff_expected = [-2, 2, -3, 3];
    sq_expected   = [4, 4, 9, 9];
    sum_expected  = 26;
    mse_expected  = 6.5;
    rmse_expected = sqrt(6.5);                   % ~2.5495
    psnr_expected = 10 * log10((255^2) / 6.5);   % ~40.0006 dB

    % 1. Difference check
    diff_actual = f - g;
    assert(isequal(diff_actual, diff_expected), 'Difference vector mismatch');

    % 2. Squared difference check
    sq_actual = diff_actual .^ 2;
    assert(isequal(sq_actual, sq_expected), 'Squared differences mismatch');

    % 3. Sum check
    assert(sum(sq_actual) == sum_expected, 'Sum of squared differences mismatch');

    % 4. MSE check
    mse_actual = sum(sq_actual) / length(f);
    assert(abs(mse_actual - mse_expected) < 1e-6, 'MSE calculation failed');

    % 5. RMSE check
    rmse_actual = sqrt(mse_actual);
    assert(abs(rmse_actual - rmse_expected) < 1e-4, 'RMSE calculation failed');

    % 6. PSNR check
    psnr_actual = 10 * log10((255^2) / mse_actual);
    assert(abs(psnr_actual - psnr_expected) < 1e-4, 'PSNR calculation failed');

    fprintf('[PASS] Equation (5) MSE:  Computed = %.4f | Expected = %.4f\n', mse_actual, mse_expected);
    fprintf('[PASS] Equation (6) RMSE: Computed = %.4f | Expected = %.4f (Paper: ~2.55)\n', rmse_actual, rmse_expected);
    fprintf('[PASS] Equation (7) PSNR: Computed = %.2f dB | Expected = %.2f dB (Paper: ~40.0 dB)\n', psnr_actual, psnr_expected);
    fprintf('\nAll metric verification tests PASSED with zero error!\n');
end

