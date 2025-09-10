function phat = mleNewtonMethod(f, data, init_phat)

%% This function is to use newton method to estimate a truncated gamma distribution
a = init_phat(1);
b = init_phat(2);

epsilon_a = 1e-4;
epsilon_b = epsilon_a * b / a;

diff = inf;

while diff > 1e-3
    v = sum(-log(f(data, a, b)));
    v1 = sum(-log(f(data, a+epsilon_a, b)));
    v2 = sum(-log(f(data, a-epsilon_a, b)));
    f1 = (v1 - v2) / (2*epsilon_a);
    f2 = abs(((v1-v)/epsilon_a - (v-v2)/epsilon_a)/epsilon_a);
    a_new = a - f1*min(0.5*abs(a/f1),1/f2);

    v1 = sum(-log(f(data, a, b+epsilon_b)));
    v2 = sum(-log(f(data, a, b-epsilon_b)));
    f1 = (v1 - v2) / (2*epsilon_b);
    f2 = abs(((v1-v)/epsilon_b - (v-v2)/epsilon_b)/epsilon_b);
    b_new = b - f1*min(0.5*abs(b/f1),1/f2);

    
    diff = abs(b_new-b) + abs(a_new-a);

    a = a_new;
    b = b_new;
end

phat = [a, b];
