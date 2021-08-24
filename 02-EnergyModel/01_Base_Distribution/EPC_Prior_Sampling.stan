// EPC_Prior_Sampling.Stan
// This Stan program defines a simple model, with a
// vector of values 'y' modeled as normally distributed
// with mean 'mu' and standard deviation 'sigma'.
//

// The input data is a vector 'y' of length 'N'.
data {
  
  int<lower=0> N; // Number of instances in the NEED Data
  int<lower=0> M; // Number of instances in the EPC data for specific region
  int<lower=1> T; // Number of households typology groups
  vector[N] E_N;
  vector[M] E_M;
  real sigma_N;
  int<lower=1, upper=T> tn[N];
  int<lower=1, upper=T> tm[M];
  
}

// The parameters accepted by the model. Our model
// accepts two parameters 'mu' and 'sigma'.
parameters {
  
  vector[T] yet;
  vector[T] mu_E;
  real<lower=0> sigma_E;
  real<lower=0> sigma;
  vector[N] zee;
  
}

transformed parameters {
  
  vector[N] Eta;
  vector[T] E;
  
  E = mu_E + sigma_E*yet;
  
  Eta = mu_E[tn] + sigma_E*zee;
  

}

// The model to be estimated. We model the output
// 'y' to be normally distributed with mean 'mu'
// and standard deviation 'sigma'.
model {
  
  zee~std_normal();
  
  E_N ~ normal(Eta[tn], sigma_N);

  
  yet~std_normal();
  
  sigma~std_normal();
  
  E_M ~ normal(E[tm], sigma);
  
}



